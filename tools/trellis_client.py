# TRELLIS.2 (Space Hugging Face « microsoft/TRELLIS.2 ») : une image -> un .glb texturé.
# Tourne sous le Python Windows de son venv (gradio_client ≥ 1.4, Python 3.10+) :
#   <venv>/Scripts/python.exe trellis_client.py <image> <sortie.glb> <graine>
# Le jeton est celui que `huggingface_hub` range par défaut : anonyme, le quota ZeroGPU
# ne suffit pas à un modèle.
import shutil, sys
from gradio_client import Client, handle_file
from huggingface_hub import get_token

src, out, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
c = Client("microsoft/TRELLIS.2", token=get_token(), verbose=False)
c.predict(api_name="/start_session")
img = c.predict(handle_file(src), api_name="/preprocess_image")
c.predict(handle_file(img), seed, "1024", api_name="/image_to_3d")
glb, _ = c.predict(200000, 2048, api_name="/extract_glb")
shutil.copy(glb, out)
