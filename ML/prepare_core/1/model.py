import numpy as np
import triton_python_backend_utils as pb_utils
import json

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
            
            # clip_feat_text = clip_feat_text[:30]
            
            ctx_l = 75
            
            tef_st = np.arange(0, ctx_l, 1.0) / ctx_l
            tef_ed = tef_st + 1.0 / ctx_l
            tef = np.stack([tef_st, tef_ed], axis=1)  # (Lv, 2)
            
            clip_feat_vid = np.concatenate([clip_feat_vid, tef], axis=-1)
            
            out_clip_vid = pb_utils.Tensor(
                "clip_vid", clip_feat_vid.astype(output0_dtype))
            
            out_clip_text = pb_utils.Tensor(
                "clip_text", clip_feat_text.astype(output0_dtype))
            
            src_vid_mask = np.ones((75))
            
            # src_txt_mask = np.ones((30))
            src_txt_mask = np.ones((77))
            
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