# 基于知识图谱的职位推荐系统

> 使用原生 Neo4j、FastAPI 与职位知识图谱，为 AI 相关岗位提供查询、画像推荐和岗位相似推荐。

## 项目概览

本项目围绕“**职位推荐**”这一目标，将原始招聘数据转换为可计算的知识图谱，并通过图数据库实现检索与推荐。系统当前聚焦 AI 相关岗位，核心流程包括：

1. 采集职位原始数据
2. 清洗并标准化字段
3. 抽取技能、福利、关键词等实体
4. 构建职位知识图谱并同步到 Neo4j
5. 通过 FastAPI 暴露查询与推荐接口
6. 通过前端页面展示推荐结果和职位一跳子图

项目采用**原生安装 Neo4j** 的方式运行，不依赖 Docker，也不使用内存版后备实现。推荐逻辑直接建立在 Neo4j 图数据之上。

## 功能特性

- **职位数据流水线**：支持抓取、清洗、去重和生成最终数据集
- **知识图谱建模**：将岗位、公司、城市、行业、技能等实体结构化建图
- **画像推荐**：根据用户技能、目标城市、行业、薪资等条件生成推荐
- **相似岗位推荐**：根据共享技能、同城、同行业、同公司关系计算相似职位
- **图谱洞察**：输出热门技能、城市、行业、福利等图谱统计视图
- **岗位检索**：支持关键词、城市、行业、学历、经验、技能、薪资筛选
- **图谱可视化**：支持查看某个岗位的一跳知识图谱
- **原生部署**：Neo4j 使用本机服务方式启动，避免容器依赖
- **工程化基础**：内置 `pytest`、CI 工作流和开发命令

## 技术栈

- **数据采集**：`Selenium`、`pyquery`、`lxml`
- **数据处理**：Python 标准库、`loguru`
- **后端服务**：`FastAPI`、`Pydantic`
- **图数据库**：`Neo4j`
- **环境配置**：`python-dotenv`
- **前端展示**：原生 HTML + `ECharts`

## 系统架构

```text
data_pipeline/
  └─ 抓取原始职位数据
      └─ 清洗、标准化、去重
          └─ datasets/processed/jobs.json
              └─ scripts/import_neo4j.py
                  └─ Neo4j 图数据库
                      ├─ FastAPI 查询接口
                      ├─ 推荐接口
                      └─ frontend/index.html 可视化页面
```

## 仓库结构

```text
.
├── job_kg/                     # 知识图谱后端与 API 服务
│   ├── api.py                  # FastAPI 路由入口
│   ├── config.py               # 环境变量与运行配置
│   ├── graph.py                # 数据标准化与图谱构建逻辑
│   ├── models.py               # 数据模型与 API schema
│   ├── repository.py           # Neo4j 持久化与查询实现
│   ├── service.py              # 服务层与技能归一化入口
│   └── taxonomy.py             # 技能/福利/关键词抽取规则
├── data_pipeline/              # 数据抓取与清洗流水线
│   ├── crawler/
│   │   └── jobsdb.py           # 招聘站点抓取实现
│   ├── config.py               # 关键词、城市、分页配置
│   ├── main.py                 # 抓取主入口
│   ├── processor.py            # 清洗与去重逻辑
│   └── requirements.txt        # 流水线依赖
├── datasets/                   # 数据产物目录
│   ├── raw/
│   │   └── jobs_raw.json       # 原始抓取结果
│   ├── interim/
│   │   └── jobs_cleaned.json   # 清洗后的中间结果
│   └── processed/
│       └── jobs.json           # 图谱导入与 API 使用的最终数据
├── frontend/
│   ├── index.html              # 前端页面
│   └── vendor/
│       └── echarts.min.js      # 本地前端依赖
├── scripts/
│   ├── import_neo4j.py         # 将最终数据导入 Neo4j
│   ├── install_neo4j_launchd.sh# macOS 原生 Neo4j 服务安装脚本
│   └── neo4j-java-runner.sh    # Neo4j Java 启动包装脚本
├── docs/
│   └── repository-structure.md # 仓库结构补充说明
├── tests/                      # 单元测试与 API 测试
├── .github/workflows/          # 持续集成配置
├── Makefile                    # 常用命令封装
├── pyproject.toml              # Python 项目元信息
├── requirements.txt            # 根依赖
├── requirements-dev.txt        # 开发与测试依赖
└── README.md
```

### 目录设计原则

- **代码与数据分离**：业务代码放在 `job_kg/`、`data_pipeline/`，数据产物统一进入 `datasets/`
- **运行入口聚合**：导入、启动、服务安装相关命令集中在 `scripts/`
- **文档与实现分层**：结构说明、补充文档统一放在 `docs/`
- **前后端松耦合**：前端静态资源独立于后端服务逻辑

## 核心设计

### 1. 数据层设计

数据被分为三层：

- `datasets/raw/jobs_raw.json`：原始抓取结果，只保留必要原始字段与详情链接
- `datasets/interim/jobs_cleaned.json`：结构清洗后的中间结果
- `datasets/processed/jobs.json`：去重、标准化后供图谱与 API 使用的最终数据

这种分层方式便于：

- 回溯抓取结果
- 调试清洗过程
- 复用最终稳定数据集

### 2. 图谱建模设计

系统将职位相关信息映射为以下核心节点类型：

- `Job`：岗位
- `Company`：公司
- `City`：城市
- `Industry`：行业
- `Degree`：学历要求
- `Experience`：经验要求
- `Skill`：技能
- `Benefit`：福利
- `Keyword`：补充关键词

核心关系包括：

- `(:Job)-[:POSTED_BY]->(:Company)`
- `(:Job)-[:LOCATED_IN]->(:City)`
- `(:Job)-[:IN_INDUSTRY]->(:Industry)`
- `(:Job)-[:REQUIRES_DEGREE]->(:Degree)`
- `(:Job)-[:REQUIRES_EXPERIENCE]->(:Experience)`
- `(:Job)-[:REQUIRES_SKILL]->(:Skill)`
- `(:Job)-[:HAS_BENEFIT]->(:Benefit)`
- `(:Job)-[:HAS_KEYWORD]->(:Keyword)`
- `(:Company)-[:BELONGS_TO]->(:Industry)`
- `(:Job)-[:SIMILAR_TO]->(:Job)`

其中 `SIMILAR_TO` 为导入阶段自动生成的岗位相似边，综合考虑共享技能、共享福利、同城、同行业和同公司信息。

### 3. 实体抽取设计

`job_kg/taxonomy.py` 中定义了技能别名、福利词和停用词规则，抽取策略如下：

- 先从 `jobTags` 中切分标签
- 对标签进行技能归一化，例如 `pytorch -> PyTorch`
- 将福利标签归到 `Benefit`
- 将非停用词且长度合理的标签归到 `Keyword`
- 再从职位标题和职位描述中补充召回技能

这种做法兼顾了：

- 显式标签抽取
- 标题/描述中的隐式技能召回
- 技能名称统一化

### 4. 推荐设计

系统包含两类推荐：

#### 画像推荐

根据用户提交的画像进行评分，核心考虑因素包括：

- 匹配技能数量
- 匹配技能覆盖率
- 匹配关键词数量
- 偏好福利匹配数量
- 目标城市是否一致
- 目标行业是否一致
- 最低薪资要求是否满足
- 学历要求与经验要求是否满足
- 与种子岗位的图谱关联度

当前画像推荐的评分权重大致为：

- 技能匹配：`4.0 * 匹配技能数`
- 技能覆盖率：`2.0 * 匹配技能覆盖率`
- 关键词匹配：`1.5 * 匹配关键词数`
- 福利偏好匹配：`1.2 * 匹配福利数`
- 城市匹配：`+3.0`
- 行业匹配：`+2.5`
- 薪资达标：`+1.0`
- 种子岗位图关联：`0.35 * 相似边分数`

推荐结果中会返回：

- `score`
- `matched_skills`
- `missing_skills`
- `reasons`
- `score_breakdown`

#### 相似岗位推荐

给定一个岗位，系统会优先基于以下图关系寻找相似职位：

- 共享技能
- 共享福利
- 同城
- 同行业
- 同公司

这类推荐适合“看完一个岗位后，继续找相近岗位”的场景。

### 5. 查询设计

`/jobs` 接口支持以下条件组合：

- `keyword`
- `city`
- `industry`
- `degree`
- `experience`
- `skills`
- `min_salary`
- `limit`

其中 `skills` 采用“**全部满足**”的过滤逻辑，也就是查询条件中的每项技能都必须出现在岗位技能集合中。

## 模块说明

### `job_kg/`

后端核心目录，负责图谱构建、Neo4j 同步、查询和推荐。

- `api.py`：定义全部 HTTP 接口，并挂载 `frontend/`
- `config.py`：从 `.env` 读取 Neo4j 连接与数据文件路径
- `graph.py`：负责原始职位数据标准化、学历经验归一化、图谱构建
- `models.py`：定义岗位、推荐、图响应等模型
- `repository.py`：所有 Neo4j 的建约束、导入、查询、推荐 Cypher 都在这里
- `service.py`：封装服务层，并对技能输入进行标准化
- `taxonomy.py`：职位标签与文本中的技能、福利、关键词抽取规则

### `data_pipeline/`

数据采集与清洗流水线。

- `crawler/jobsdb.py`：职位抓取逻辑
- `config.py`：抓取关键词、城市、分页和条数限制
- `main.py`：串联抓取、清洗、去重并生成三层数据文件
- `processor.py`：清洗和去重实现

### `scripts/`

运维与导入脚本目录。

- `import_neo4j.py`：从 `datasets/processed/jobs.json` 导入 Neo4j
- `import_neo4j.py`：导入完成后会自动重建相似岗位边
- `install_neo4j_launchd.sh`：在 macOS 上注册本机 Neo4j 启动服务
- `neo4j-java-runner.sh`：为本机 Neo4j 进程设置 Java 启动参数

### `frontend/`

静态页面与本地前端依赖，主要用于：

- 输入用户画像
- 展示推荐岗位列表
- 展示岗位一跳图谱

## 数据流转

```text
抓取网页
  -> raw/jobs_raw.json
  -> interim/jobs_cleaned.json
  -> processed/jobs.json
  -> load_graph_from_file(...)
  -> sync_graph(...)
  -> Neo4j
  -> FastAPI 查询 / 推荐接口
  -> 前端页面展示
```

## 环境要求

### 基础环境

- Python `>= 3.10`
- Java `21`
- Neo4j `5.x`
- macOS + Homebrew（仓库内 Neo4j 服务脚本基于该环境）

### Python 依赖

根依赖见 `requirements.txt`，其中包含：

- 后端依赖：`fastapi`、`uvicorn`、`neo4j`、`pydantic`、`python-dotenv`
- 流水线依赖：`selenium`、`webdriver-manager`、`pyquery`、`lxml`、`loguru`

安装命令：

```bash
pip install -r requirements.txt
```

或：

```bash
make install
```

## 配置说明

复制环境变量模板：

```bash
cp .env.example .env
```

`.env` 中需要配置：

```env
KG_DATA_FILE=datasets/processed/jobs.json
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=change_me
NEO4J_DATABASE=neo4j
```

参数含义如下：

- `KG_DATA_FILE`：导入图谱时读取的最终数据文件
- `NEO4J_URI`：Neo4j Bolt 连接地址
- `NEO4J_USER`：Neo4j 用户名
- `NEO4J_PASSWORD`：Neo4j 密码
- `NEO4J_DATABASE`：目标数据库名，默认是 `neo4j`

## 使用方式

### 1. 安装 Neo4j（原生方式）

本项目使用原生 Neo4j，不使用 Docker。

如果是 macOS + Homebrew 环境，可使用：

```bash
brew install neo4j
brew install openjdk@21
neo4j-admin dbms set-initial-password <your-password>
bash scripts/install_neo4j_launchd.sh
```

查看 Neo4j 服务状态：

```bash
launchctl print gui/$(id -u)/jobkg.neo4j | sed -n '1,80p'
```

Neo4j 浏览器访问地址：

```text
http://localhost:7474
```

如果你已经初始化过数据库密码，则不需要重复执行：

```bash
neo4j-admin dbms set-initial-password <your-password>
```

### 2. 准备环境变量

```bash
cp .env.example .env
```

然后将 `.env` 中的 `NEO4J_PASSWORD` 改成你设置的密码。

### 3. 导入图谱数据

```bash
python scripts/import_neo4j.py
```

或：

```bash
make import-graph
```

该脚本会：

- 读取 `datasets/processed/jobs.json`
- 进行标准化与实体抽取
- 创建 Neo4j 约束
- 清空并重建目标图谱

### 4. 启动 API 服务

```bash
uvicorn job_kg.api:app --reload
```

或：

```bash
make run-api
```

启动后访问：

- 首页：`http://127.0.0.1:8000/`
- OpenAPI 文档：`http://127.0.0.1:8000/docs`
- ReDoc 文档：`http://127.0.0.1:8000/redoc`

### 5. 重新抓取与生成数据

```bash
python -m data_pipeline
```

或：

```bash
make crawl
```

运行后会生成：

- `datasets/raw/jobs_raw.json`
- `datasets/interim/jobs_cleaned.json`
- `datasets/processed/jobs.json`

## Makefile 命令

仓库根目录内置了常用命令：

```bash
make install       # 安装 Python 依赖
make crawl         # 重新抓取并生成数据
make import-graph  # 导入 Neo4j 图谱
make run-api       # 启动 FastAPI
make compile       # 编译检查 Python 文件
```

## API 说明

### 健康检查

```http
GET /health
```

返回服务状态与当前后端类型。

### 系统统计

```http
GET /stats
```

用于查看当前图谱中的岗位、公司、技能、城市、行业等统计信息。

### 岗位查询

```http
GET /jobs
```

支持参数：

- `keyword`
- `city`
- `industry`
- `degree`
- `experience`
- `skills`
- `min_salary`
- `limit`

示例：

```bash
curl "http://127.0.0.1:8000/jobs?city=上海&skills=机器学习&min_salary=10"
```

### 单岗位详情

```http
GET /jobs/{job_id}
```

返回某个岗位的结构化信息。

### 岗位一跳子图

```http
GET /jobs/{job_id}/graph
```

返回该岗位与公司、技能、城市、行业等直接相连节点的子图。

示例：

```bash
curl http://127.0.0.1:8000/jobs/171714274/graph
```

### 相似岗位推荐

```http
GET /jobs/{job_id}/similar
```

参数：

- `top_k`

### 画像推荐

```http
POST /recommend/profile
```

请求体示例：

```json
{
  "skills": ["Python", "PyTorch", "机器学习"],
  "desired_city": "上海",
  "desired_industry": "互联网/电子商务",
  "degree": "本科",
  "experience": "3年",
  "min_salary": 10,
  "keywords": ["大模型", "NLP"],
  "preferred_benefits": ["带薪年假", "弹性工作"],
  "seed_job_id": "171700045",
  "top_k": 5
}
```

调用示例：

```bash
curl -X POST http://127.0.0.1:8000/recommend/profile \
  -H "Content-Type: application/json" \
  -d '{
    "skills": ["Python", "PyTorch", "机器学习"],
    "desired_city": "上海",
    "min_salary": 10,
    "preferred_benefits": ["带薪年假", "弹性工作"],
    "top_k": 5
  }'
```

### 热门技能统计

```http
GET /skills/top
```

参数：

- `limit`

### 图谱洞察

```http
GET /graph/insights
```

返回热门技能、城市、行业、福利等图谱洞察信息。

## 关键数据字段

原始或处理中常见字段说明：

| 字段 | 含义 |
| --- | --- |
| `jobName` | 职位名称 |
| `companyName` | 公司名称 |
| `jobAreaString` | 工作地点 |
| `degreeString` | 学历要求 |
| `workYearString` | 工作经验 |
| `jobTags` | 岗位标签，混合了技能、方向、福利等内容 |
| `jobDescribe` | 岗位描述 |
| `companyTypeString` | 公司类型 |
| `companySizeString` | 公司规模 |
| `industryType1Str` | 行业 |
| `salaryMin` | 最低薪资，单位 `k/月` |
| `salaryMax` | 最高薪资，单位 `k/月` |

## 开发与校验

### 编译检查

```bash
python -m compileall job_kg data_pipeline scripts
```

或：

```bash
make compile
```

### 运行测试

```bash
pip install -r requirements-dev.txt
pytest
```

或：

```bash
make install-dev
make test
```

### 持续集成

仓库内置 GitHub Actions 工作流，默认执行：

- Python 依赖安装
- `compileall` 编译检查
- `pytest` 自动测试

### 重新导入并验证接口

```bash
python scripts/import_neo4j.py
uvicorn job_kg.api:app --reload
```

然后访问：

- `http://127.0.0.1:8000/health`
- `http://127.0.0.1:8000/stats`
- `http://127.0.0.1:8000/docs`

## 常见问题

### 1. 启动 API 时提示缺少环境变量

说明 `.env` 未配置完整。至少需要：

- `NEO4J_URI`
- `NEO4J_USER`
- `NEO4J_PASSWORD`
- `NEO4J_DATABASE`

### 2. 启动 API 时提示 Neo4j 中尚未导入岗位图谱

先执行：

```bash
python scripts/import_neo4j.py
```

### 3. 导入失败或连不上 Neo4j

按顺序检查：

- Neo4j 服务是否已启动
- `.env` 中密码是否正确
- `NEO4J_URI` 是否为 `bolt://localhost:7687`
- Neo4j 浏览器 `http://localhost:7474` 是否能打开

### 4. 重新抓取后为什么推荐结果没有变化

抓取只会更新 `datasets/` 中的数据文件；如果要让 Neo4j 中的图谱同步更新，还需要重新执行：

```bash
python scripts/import_neo4j.py
```

## 项目现状

当前仓库已经完成：

- 数据抓取与清洗流程
- 基于 Neo4j 的职位知识图谱
- 岗位查询与统计接口
- 画像推荐与相似岗位推荐
- 前端静态展示页面

如果你要继续扩展，比较自然的方向包括：

- 增加更多招聘来源
- 引入更细粒度的技能本体
- 增强岗位描述语义抽取
- 加入用户行为反馈优化推荐排序
