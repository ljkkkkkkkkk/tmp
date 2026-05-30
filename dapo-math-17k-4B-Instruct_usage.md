# dapo-math-17k-4B-Instruct 数据集使用说明

## 文件

| 文件 | 大小 | 说明 |
|------|------|------|
| `dapo-math-17k-4B-Instruct.parquet` | ~436MB | 过滤后的训练数据（剔除 8/8 全对的题目） |
| `dapo-math-17k-4B-Instruct_offline_accuracy.json` | ~284KB | 离线准确率，格式 `{prompt_idx: [n_correct, n_samples]}` |

## 生成方式

```bash
cd /lianjiakun1 && /lianjiakun1/verl/lzc_venv/bin/python3 verl/scripts/rollout_dapo_17k_4b_instruct.py
```

脚本用 Qwen3-4B-Instruct 对 dapo-math-17k 每条题目采样 8 次，过滤掉 8/8 全对的题目（这些题目对训练无意义），同时记录每条题目的离线正确率。

## 在训练脚本中使用

### 1. 替换训练数据

在 shell 脚本中，将 `data.train_files` 指向新的 parquet：

```bash
data.train_files=/lianjiakun1/data/dataset/deepscaler/dapo-math-17k-4B-Instruct.parquet
```

### 2. 配合 DynamicFilter 使用 offline accuracy

DynamicFilter 会自动加载 `offline_accuracy.json` 作为先验，跳过历史上准确率高的题目：

```bash
# 训练脚本中启用 dynamic filter
algorithm.filter_groups.enable=True \
algorithm.filter_groups.metric=acc \
algorithm.filter_groups.max_num_gen_batches=10 \
```

代码中 `DynamicFilter` 初始化时会读取 `offline_accuracy.json`（`verl/utils/dynamic_filter.py`）：

```python
# 在 dapo_ray_trainer.py 中
self.dynamic_filter = DynamicFilter(
    ...
    offline_accuracy_path="/lianjiakun1/data/dataset/deepscaler/dapo-math-17k-4B-Instruct_offline_accuracy.json",
)
```

### 3. 完整训练脚本示例

```bash
# 基于 bf16.sh 改造，使用 4B-Instruct 预打分的过滤数据
python3 -m recipe.dapo.main_dapo \
    --config-name='dapo_megatron_trainer.yaml' \
    data.train_files=/lianjiakun1/data/dataset/deepscaler/dapo-math-17k-4B-Instruct.parquet \
    ...其他参数...
```

## 数据格式

**Parquet 字段**（比原始数据多了 rollout 相关字段）：
- `prompt` — 原始 prompt
- `data_source` — 数据来源
- `reward_model` — ground truth 等信息
- `rollout_responses` — 4B-Instruct 的 8 次采样回答
- `rollout_scores` — 8 次回答的得分
- `rollout_preds` — 8 次回答提取的答案
- `n_correct` — 8 次采样中正确的次数

**offline_accuracy.json 格式**：
```json
{
  "0": [3, 8],     // prompt 0: 8 次中正确 3 次
  "1": [0, 8],     // prompt 1: 全错
  "2": [5, 8],     // prompt 2: 正确 5 次
  ...
}
```
