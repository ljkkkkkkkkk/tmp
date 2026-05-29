#!/bin/bash
# ============================================================
# lzc_venv full replication script
# Generated from: /lianjiakun1/verl/lzc_venv
# Target: Python 3.12.12, CUDA 12.9, Torch 2.9.0+cu129
# Usage: bash install_lzc_venv.sh /path/to/new_venv
# ============================================================
set -e

VENV_DIR="${1:-$PWD/lzc_venv}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Creating venv at $VENV_DIR ==="
python3.12 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel

# ============================================================
# Step 1: PyPI packages (from pip freeze)
# ============================================================
echo "=== Installing PyPI packages ==="
# Strip git+/file:// entries - install standard packages first
grep -vE '^(@ |file://|git\+)' "$SCRIPT_DIR/lzc_venv_freeze_full.txt" > /tmp/lzc_std_pkgs.txt
pip install -r /tmp/lzc_std_pkgs.txt

# ============================================================
# Step 2: CUDA-specific packages (must match CUDA 12.9 + Torch 2.9.x)
# ============================================================
echo "=== Installing CUDA packages ==="
pip install torch==2.9.0 torchvision==0.24.0 torchaudio==2.9.0 --index-url https://download.pytorch.org/whl/cu129
pip install flash-attn==2.8.3 --no-build-isolation

# ============================================================
# Step 3: Git packages
# ============================================================
echo "=== Installing git packages ==="

# megatron-core
pip install git+https://github.com/NVIDIA/Megatron-LM.git@3bec9aa97dda898d16ff5a89bac0ed2b6682b172

# transformer_engine (from NVIDIA/TransformerEngine)
pip install git+https://github.com/NVIDIA/TransformerEngine.git@769ed778341a32c8c593fda391700c0a80f65f1f#subdirectory=transformer_engine/pytorch

# Additional git packages from requirements (not in current venv but needed for full alignment)
# pip install git+https://github.com/NVIDIA/apex.git@10417aceddd7d5d05d7cbf7b0fc2daad1105f8b4
# pip install git+https://github.com/ISEEKYAN/mbridge.git@89eb10887887bc74853f89a4de258c0702932a1c
# pip install git+https://github.com/fzyzcjy/Megatron-Bridge.git@35b4ebfc486fb15dcc0273ceea804c3606be948a
# pip install git+https://github.com/fzyzcjy/torch_memory_saver.git@dc6876905830430b5054325fa4211ff302169c6b

# ============================================================
# Step 4: sglang (from tarball)
# ============================================================
echo "=== Installing sglang ==="
if [ -f "$SCRIPT_DIR/sglang.tar.gz" ]; then
    tar -xzf "$SCRIPT_DIR/sglang.tar.gz" -C /tmp/
    pip install -e "/tmp/sglang/python"
    # sglang-router if needed:
    # pip install -e "/tmp/sglang/sgl-model-gateway/..."
fi

# ============================================================
# Step 5: DeepEP (from tarball)
# ============================================================
echo "=== Installing DeepEP ==="
if [ -f "$SCRIPT_DIR/DeepEP.tar.gz" ]; then
    tar -xzf "$SCRIPT_DIR/DeepEP.tar.gz" -C /tmp/
    pip install -e /tmp/DeepEP
fi

# ============================================================
# Step 6: int4_qat (from tarball)
# ============================================================
echo "=== Installing fake_int4_quant_cuda ==="
if [ -f "$SCRIPT_DIR/int4_qat.tar.gz" ]; then
    tar -xzf "$SCRIPT_DIR/int4_qat.tar.gz" -C /tmp/
    pip install -e /tmp/int4_qat
fi

# ============================================================
# Step 7: deep_gemm (build from source or use wheel)
# ============================================================
echo "=== Installing deep_gemm ==="
git clone https://github.com/deepseek-ai/DeepGEMM /tmp/DeepGEMM_build
cd /tmp/DeepGEMM_build && pip install -e .

# ============================================================
# Step 8: transformer_engine_cu12 (rebuild or install from wheel)
# ============================================================
echo "=== Installing transformer_engine ==="
pip install transformer_engine_torch --no-deps
pip install transformer_engine_cu12

# ============================================================
# Step 9: verl (editable, from source)
# ============================================================
echo "=== Installing verl (editable) ==="
# This requires the verl source repo. Update path as needed.
# pip install -e /path/to/new_verl/verl

# ============================================================
# Step 10: Verify
# ============================================================
echo "=== Verification ==="
python -c "import torch; print('torch:', torch.__version__, 'CUDA:', torch.cuda.is_available())"
python -c "import vllm; print('vllm:', vllm.__version__)"
python -c "import flash_attn; print('flash_attn OK')" 2>/dev/null || echo "flash_attn: check manually"
python -c "import sglang; print('sglang OK')" 2>/dev/null || echo "sglang: not verified"

echo ""
echo "=== Done ==="
echo "Activate: source $VENV_DIR/bin/activate"
