import json

import triton_python_backend_utils as pb_utils
import numpy as np

# import ffmpeg
import subprocess
import sys

try:
    import ffmpeg
    import ftfy
    import regex as re
except ImportError:
    subprocess.check_call(["apt-get", "update"])
    subprocess.check_call(["apt-get", "install", "-y", "ffmpeg"])
    # subprocess.run(["sudo", "apt-get", "install", "-y", "ffmpeg"], check=True)
    subprocess.check_call([sys.executable, "-m", "pip", "install", 'ffmpeg-python'])
    subprocess.check_call([sys.executable, "-m", "pip", "install", 'ftfy'])
    subprocess.check_call([sys.executable, "-m", "pip", "install", 'regex'])
finally:
    import ffmpeg
    import ftfy
    import regex as re
import math
from typing import Union, List

import gzip
import html
import os
from functools import lru_cache

# import ftfy
# import regex as re


@lru_cache()
def default_bpe():
    bpe_path = "/model_dir/QD-DETR/run_on_video/clip/bpe_simple_vocab_16e6.txt.gz"
    #return os.path.join(os.path.dirname(os.path.abspath(__file__)), "bpe_simple_vocab_16e6.txt.gz")
    return bpe_path

@lru_cache()
def bytes_to_unicode():
    """
    Returns list of utf-8 byte and a corresponding list of unicode strings.
    The reversible bpe codes work on unicode strings.
    This means you need a large # of unicode characters in your vocab if you want to avoid UNKs.
    When you're at something like a 10B token dataset you end up needing around 5K for decent coverage.
    This is a signficant percentage of your normal, say, 32K bpe vocab.
    To avoid that, we want lookup tables between utf-8 bytes and unicode strings.
    And avoids mapping to whitespace/control characters the bpe code barfs on.
    """
    bs = list(range(ord("!"), ord("~")+1))+list(range(ord("¡"), ord("¬")+1))+list(range(ord("®"), ord("ÿ")+1))
    cs = bs[:]
    n = 0
    for b in range(2**8):
        if b not in bs:
            bs.append(b)
            cs.append(2**8+n)
            n += 1
    cs = [chr(n) for n in cs]
    return dict(zip(bs, cs))


def get_pairs(word):
    """Return set of symbol pairs in a word.
    Word is represented as tuple of symbols (symbols being variable-length strings).
    """
    pairs = set()
    prev_char = word[0]
    for char in word[1:]:
        pairs.add((prev_char, char))
        prev_char = char
    return pairs


def basic_clean(text):
    text = ftfy.fix_text(text)
    text = html.unescape(html.unescape(text))
    return text.strip()


def whitespace_clean(text):
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()
    return text

class SimpleTokenizer(object):
    def __init__(self, bpe_path: str = default_bpe()):
        self.byte_encoder = bytes_to_unicode()
        self.byte_decoder = {v: k for k, v in self.byte_encoder.items()}
        merges = gzip.open(bpe_path).read().decode("utf-8").split('\n')
        merges = merges[1:49152-256-2+1]
        merges = [tuple(merge.split()) for merge in merges]
        vocab = list(bytes_to_unicode().values())
        vocab = vocab + [v+'</w>' for v in vocab]
        for merge in merges:
            vocab.append(''.join(merge))
        vocab.extend(['<|startoftext|>', '<|endoftext|>'])
        self.encoder = dict(zip(vocab, range(len(vocab))))
        self.decoder = {v: k for k, v in self.encoder.items()}
        self.bpe_ranks = dict(zip(merges, range(len(merges))))
        self.cache = {'<|startoftext|>': '<|startoftext|>', '<|endoftext|>': '<|endoftext|>'}
        self.pat = re.compile(r"""<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+""", re.IGNORECASE)

    def bpe(self, token):
        if token in self.cache:
            return self.cache[token]
        word = tuple(token[:-1]) + ( token[-1] + '</w>',)
        pairs = get_pairs(word)

        if not pairs:
            return token+'</w>'

        while True:
            bigram = min(pairs, key = lambda pair: self.bpe_ranks.get(pair, float('inf')))
            if bigram not in self.bpe_ranks:
                break
            first, second = bigram
            new_word = []
            i = 0
            while i < len(word):
                try:
                    j = word.index(first, i)
                    new_word.extend(word[i:j])
                    i = j
                except:
                    new_word.extend(word[i:])
                    break

                if word[i] == first and i < len(word)-1 and word[i+1] == second:
                    new_word.append(first+second)
                    i += 2
                else:
                    new_word.append(word[i])
                    i += 1
            new_word = tuple(new_word)
            word = new_word
            if len(word) == 1:
                break
            else:
                pairs = get_pairs(word)
        word = ' '.join(word)
        self.cache[token] = word
        return word

    def encode(self, text):
        bpe_tokens = []
        text = whitespace_clean(basic_clean(text)).lower()
        for token in re.findall(self.pat, text):
            token = ''.join(self.byte_encoder[b] for b in token.encode('utf-8'))
            bpe_tokens.extend(self.encoder[bpe_token] for bpe_token in self.bpe(token).split(' '))
        return bpe_tokens

    def decode(self, tokens):
        text = ''.join([self.decoder[token] for token in tokens])
        text = bytearray([self.byte_decoder[c] for c in text]).decode('utf-8', errors="replace").replace('</w>', ' ')
        return text

class Normalize(object):

    def __init__(self, mean, std):
        self.mean = np.array(mean).reshape(1, 3, 1, 1)
        self.std = np.array(std).reshape(1, 3, 1, 1)

    def __call__(self, tensor):
        tensor = (tensor - self.mean) / (self.std + 1e-8)
        return tensor
    
class Preprocessing(object):

    def __init__(self):
        self.norm = Normalize(
            mean=[0.48145466, 0.4578275, 0.40821073],
            std=[0.26862954, 0.26130258, 0.27577711])

    def __call__(self, tensor):
        tensor = tensor / 255.0
        tensor = self.norm(tensor)
        return tensor
    
def convert_to_float(frac_str):
    try:
        return float(frac_str)
    except ValueError:
        try:
            num, denom = frac_str.split('/')
        except ValueError:
            return None
        try:
            leading, num = num.split(' ')
        except ValueError:
            return float(num) / float(denom)
        if float(leading) < 0:
            sign_mult = -1
        else:
            sign_mult = 1
        return float(leading) + sign_mult * (float(num) / float(denom))

def _get_video_info(video_path):
    probe = ffmpeg.probe(video_path)
    video_stream = next((stream for stream in probe['streams']
                            if stream['codec_type'] == 'video'), None)
    width = int(video_stream['width'])
    height = int(video_stream['height'])
    fps = math.floor(convert_to_float(video_stream['avg_frame_rate']))
    try:
        frames_length = int(video_stream['nb_frames'])
        duration = float(video_stream['duration'])
    except Exception:
        frames_length, duration = -1, -1
    info = {"duration": duration, "frames_length": frames_length,
            "fps": fps, "height": height, "width": width}
    return info

def _get_output_dim(h, w):
    size = 224
    if isinstance(size, tuple) and len(size) == 2:
        return size
    elif h >= w:
        return int(h * size / w), size
    else:
        return size, int(w * size / h)

def read_video_from_file(video_path):
    try:
        info = _get_video_info(video_path)
        h, w = info["height"], info["width"]
    except Exception:
        print('ffprobe failed at: {}'.format(video_path))
        return {'video': np.zeros(1), 'input': video_path, 'info': {}}
    
    height, width = _get_output_dim(h, w)
    num_target_frames = 75  # 목표 프레임 수

    try:
        duration = float(info["duration"])  # 비디오의 총 길이 (초 단위)
        total_frames = int(info["frames_length"])  # 비디오의 총 프레임 수
        fps = total_frames / duration  # 초당 프레임 수
        frames_interval = max(1, int(total_frames / num_target_frames))  # 프레임 간 간격
        select_fps = fps / frames_interval  # 선택된 프레임의 프레임 속도
    except Exception:
        print("Error calculating FPS. Using default.")
        select_fps = 1/2

    # ffmpeg 명령을 사용하여 비디오 처리
    cmd = (
        ffmpeg
        .input(video_path)
        .filter('fps', fps=select_fps)
        .filter('scale', width, height)
    )
    
    centercrop = True
    size = 224
    if centercrop:
        x = int((width - size) / 2.0)
        y = int((height - size) / 2.0)
        cmd = cmd.crop(x, y, size, size)

    out, _ = (
        cmd.output('pipe:', format='rawvideo', pix_fmt='rgb24')
        .run(capture_stdout=True, quiet=True)
    )

    if centercrop and isinstance(size, int):
        height, width = size, size

    # 프레임 데이터를 numpy 배열로 변환
    video = np.frombuffer(out, np.uint8).reshape([-1, height, width, 3])
    video = video.transpose(0, 3, 1, 2)  # 프레임 형태 변경
    
    if video.shape[0] > num_target_frames:
        video = video[:num_target_frames]  # 첫 75개 프레임만 사용
    elif video.shape[0] < num_target_frames:
        # 필요하다면 여러번 같은 프레임을 반복
        repeat_factor = (num_target_frames + video.shape[0] - 1) // video.shape[0]
        video = np.tile(video, (repeat_factor, 1, 1, 1))[:num_target_frames]

    return video

def tokenize(texts: Union[str, List[str]], context_length: int = 77, max_valid_length: int = 32):
    """
    Returns the tokenized representation of given input string(s)

    Parameters
    ----------
    texts : Union[str, List[str]]
        An input string or a list of input strings to tokenize

    context_length : int
        The context length to use; all CLIP models use 77 as the context length

    max_valid_length:

    Returns
    -------
    A two-dimensional tensor containing the resulting tokens, shape = [number of input strings, context_length]
    """
    if isinstance(texts, str):
        texts = [texts]
    _tokenizer = SimpleTokenizer()
    sot_token = _tokenizer.encoder["<|startoftext|>"]
    eot_token = _tokenizer.encoder["<|endoftext|>"]
    all_tokens = [[sot_token] + _tokenizer.encode(text)[:max_valid_length-2] + [eot_token] for text in texts]
    result = np.zeros((len(all_tokens), context_length), dtype=np.int64)
    
    for i, tokens in enumerate(all_tokens):
        if len(tokens) > context_length:
            raise RuntimeError(f"Input {all_tokens[i]} is too long for context length {context_length}")
        # Insert tokens into the result array
        result[i, :len(tokens)] = np.array(tokens, dtype=np.int64)
    result = result.reshape(-1)
    return result


def encode(video_path, query):
    video_frames = read_video_from_file(video_path)
    print("pre_video_frame:", video_frames.shape)
    video_frames = Preprocessing()(video_frames)
    print("video_frame:", video_frames.shape)

    encoded_texts = tokenize(query, context_length=77)
    print("encoded_texts:", encoded_texts.shape)
    return video_frames, encoded_texts

class TritonPythonModel:

    def initialize(self, args):

        # You must parse model_config. JSON string is not parsed here
        self.model_config = model_config = json.loads(args["model_config"])

        # Get OUTPUT0 configuration
        output0_config = pb_utils.get_output_config_by_name(
            model_config, "video")

        # Get OUTPUT1 configuration
        output1_config = pb_utils.get_output_config_by_name(
            model_config, "text")

        # Convert Triton types to numpy types
        self.output0_dtype = pb_utils.triton_string_to_numpy(
            output0_config["data_type"]
        )
        self.output1_dtype = pb_utils.triton_string_to_numpy(
            output1_config["data_type"]
        )

    def execute(self, requests):

        output0_dtype = self.output0_dtype
        output1_dtype = self.output1_dtype

        responses = []

        # Every Python backend must iterate over everyone of the requests
        # and create a pb_utils.InferenceResponse for each of them.
        for request in requests:
            # Get INPUT0
            in_0 = pb_utils.get_input_tensor_by_name(request, "INPUT0")
            # Get INPUT1
            in_1 = pb_utils.get_input_tensor_by_name(request, "INPUT1")

            print(f"INPUT VALUE: {in_0.as_numpy()[0].decode('UTF-8')}")
            print(f"INPUT VALUE: {in_1.as_numpy()[0].decode('UTF-8')}")
            
            video, text = encode(in_0.as_numpy()[0].decode('UTF-8'), in_1.as_numpy()[0].decode('UTF-8'))
            
            print(video.shape, text.shape)

            # Create output tensors

            # out_tensor_0 = pb_utils.Tensor(
            #     "video", np.random.random((75, 3, 224, 224)).astype(output0_dtype))
            # out_tensor_1 = pb_utils.Tensor(
            #     "text", np.random.random((77)).astype(output1_dtype))
            out_tensor_0 = pb_utils.Tensor(
                "video", video.astype(output0_dtype))
            out_tensor_1 = pb_utils.Tensor(
                "text", text.astype(output1_dtype))
            inference_response = pb_utils.InferenceResponse(
                output_tensors=[out_tensor_0, out_tensor_1]
            )
            responses.append(inference_response)

        # You should return a list of pb_utils.InferenceResponse. Length
        # of this list must match the length of `requests` list.
        return responses
