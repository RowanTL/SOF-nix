from pathlib import Path

from scene.gaussian_model import GaussianModel

gmodel: GaussianModel = GaussianModel(sh_degree=3)
ply_path: Path = Path("/home/rtorblane/Documents/Blender/gaussians/griffin.ply")
gmodel.load_ply(ply_path)

pass
