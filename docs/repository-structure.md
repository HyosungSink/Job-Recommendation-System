# 仓库结构说明

本仓库按“代码 / 数据 / 前端 / 运维脚本”分层组织：

## 顶层目录

- `job_kg/`：知识图谱推荐后端与 FastAPI 服务
- `data_pipeline/`：职位数据抓取、清洗、去重流水线
- `datasets/`：数据产物目录，不混放业务代码
- `frontend/`：前端静态页面与本地前端依赖
- `scripts/`：Neo4j 导入、服务安装等运维脚本
- `docs/`：补充文档
- `tests/`：单元测试与接口测试
- `.github/workflows/`：持续集成配置

## `datasets/` 分层

- `datasets/raw/`：原始抓取结果
- `datasets/interim/`：清洗后的中间结果
- `datasets/processed/`：推荐系统实际消费的最终数据

## 推荐的维护原则

- 新增业务代码优先放在 `job_kg/` 或 `data_pipeline/`
- 新增数据文件不要放到代码目录
- 启动、导入、部署相关命令优先放在 `scripts/`
- 说明性文档统一放在 `docs/`
- 测试代码统一放在 `tests/`
