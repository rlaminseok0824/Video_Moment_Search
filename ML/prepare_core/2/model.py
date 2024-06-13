import numpy as np
import triton_python_backend_utils as pb_utils
import json

def pad_sequences_1d_np(sequences, dtype=np.float32, fixed_length=None):
    """ Pad a single-nested list or a sequence of n-d array (np.ndarray) into a (n+1)-d array,
        only allow the first dim has variable lengths, using NumPy.
    Args:
        sequences: list(n-d tensor or list)
        dtype: np.dtype
        fixed_length: pad all seq in sequences to fixed length. All seq should have a length <= fixed_length.
            return will be of shape [len(sequences), fixed_length, ...]
    Returns:
        padded_seqs: (n+1)-d array padded with zeros
        mask: 2d array of the same shape as the first two dims of padded_seqs, 1 indicate valid, 0 otherwise
    """
    # Convert lists to numpy arrays if not already
    if isinstance(sequences[0], list):
        sequences = [np.array(s, dtype=dtype) for s in sequences]

    # Infer dimensions and lengths
    extra_dims = sequences[0].shape[1:]  # the extra dimensions should be consistent across all elements
    lengths = [len(seq) for seq in sequences]
    max_length = fixed_length if fixed_length is not None else max(lengths)
    
    # Initialize padded sequences and mask arrays
    padded_seqs = np.zeros((len(sequences), max_length) + extra_dims, dtype=dtype)
    mask = np.zeros((len(sequences), max_length), dtype=np.float32)
    
    # Populate padded sequences and mask
    for idx, seq in enumerate(sequences):
        end = lengths[idx]
        padded_seqs[idx, :end] = seq
        mask[idx, :end] = 1

    return padded_seqs, mask

class TritonPythonModel:

    def initialize(self, args):

        # You must parse model_config. JSON string is not parsed here
        self.model_config = model_config = json.loads(args["model_config"])

        # Get OUTPUT0 configuration
        output0_config = pb_utils.get_output_config_by_name(
            model_config, "clip_vid")
        
        output1_config = pb_utils.get_output_config_by_name(
            model_config, "clip_vid_mask")

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
            # Get input tensors
            clip_feat_vid = pb_utils.get_input_tensor_by_name(request, "clip_vid").as_numpy()
            
            clip_feat_text = pb_utils.get_input_tensor_by_name(request, "clip_text").as_numpy()
            
            # normalize clip_feat_vid, same like F.normalize(video_feats, dim=-1, eps=1e-5)
            clip_feat_vid = clip_feat_vid / np.linalg.norm(clip_feat_vid, axis=-1, keepdims=True)
            
            # clip_feat_text = clip_feat_text[:30]
            
            ctx_l = 75
            
            tef_st = np.arange(0, ctx_l, 1.0) / ctx_l
            tef_ed = tef_st + 1.0 / ctx_l
            tef = np.stack([tef_st, tef_ed], axis=1)  # (Lv, 2)
            
            clip_feat_vid = np.concatenate([clip_feat_vid, tef], axis=-1)
            
            out_clip_vid = pb_utils.Tensor(
                "clip_vid", clip_feat_vid.astype(output0_dtype))
            
            # out_clip_text = pb_utils.Tensor(
            #     "clip_text", clip_feat_text.astype(output0_dtype))
            
            src_vid_mask = np.ones((75))
            
            # src_txt_mask = np.ones((30))
            # src_txt_mask = np.ones((77))
            
            clip_feat_text, src_txt_mask = pad_sequences_1d_np([clip_feat_text])
            
            clip_feat_text = clip_feat_text / np.linalg.norm(clip_feat_text, axis=-1, keepdims=True)
            
            out_clip_text = pb_utils.Tensor(
                "clip_text", clip_feat_text.astype(output0_dtype))
            
            out_vid_mask = pb_utils.Tensor(
                "clip_vid_mask", src_vid_mask.astype(output1_dtype))
            
            out_txt_mask = pb_utils.Tensor(
                "clip_text_mask", src_txt_mask.astype(output1_dtype))
            
            inference_response = pb_utils.InferenceResponse(
                output_tensors=[out_clip_vid, out_clip_text, out_vid_mask, out_txt_mask]
            )
            
            

            # Create output tensors

            # out_tensor_0 = pb_utils.Tensor(
            #     "video", np.random.random((75, 3, 224, 224)).astype(output0_dtype))
            # out_tensor_1 = pb_utils.Tensor(
            #     "text", np.random.random((77)).astype(output1_dtype))
            # out_tensor_0 = pb_utils.Tensor(
            #     "video", video.astype(output0_dtype))
            # out_tensor_1 = pb_utils.Tensor(
            #     "text", text.astype(output1_dtype))
            # inference_response = pb_utils.InferenceResponse(
            #     output_tensors=[out_tensor_0, out_tensor_1]
            # )
            responses.append(inference_response)

        # You should return a list of pb_utils.InferenceResponse. Length
        # of this list must match the length of `requests` list.
        return responses