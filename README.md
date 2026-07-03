# ecommerce-user-behavior-analysis
MySQL + Tableau E-commerce User Behavior Analysis

## 📌 项目目录 (Tableau & SQL Project Index)
*   [1. 项目文件树 (Project Directory Tree)](#1-项目文件树-project-directory-tree)
*   [2. 核心目录与模块说明 (Directory & Module Descriptions)](#2-核心目录与模块说明-directory--module-descriptions)
*   [3. 核心业务指标摘要 (Key Business Metrics)](#3-核心业务指标摘要-key-business-metrics)
*   [4. 核心看板预览 (Dashboard Preview)](#4-核心看板预览-dashboard-preview)


## 1. 项目文件树 (Project Directory Tree)

```text
ecommerce-user-behavior-analysis
│
├── README.md                      # 项目主说明文档（当前文件）
│
├── data                           # 数据存放目录
│   ├── raw                        # 原始数据
│   │   └── userbehavior.csv       # 原始淘宝用户行为数据集
│   └── processed                  # 清洗后导出的结构化指标数据
│       ├── df_pv_uv.csv           # 每日 PV/UV 大盘基础数据
│       ├── df_retention.csv       # 活动前后用户次日/三日留存数据
│       ├── df_timeseries.csv      # 分时段（24小时）多度量流量数据
│       └── ...                    # RFM、品类商品热门表等
│
├── sql                            # MySQL 分析脚本目录
│   ├── 01_data_cleaning.sql       # 缺失值处理、重复值去重、时间格式转换
│   ├── 02_user_analysis.sql       # 大盘流量指标（PV/UV）与分时活跃度计算
│   ├── 03_conversion.sql          # 浏览-收藏/加购-购买 全链路漏斗计算
│   ├── 04_rfm.sql                 # RFM 模型构建与 R/F 得分用户分层
│   └── 05_product_analysis.sql    # 热门品类、TOP10商品及转化率矩阵提取
│
├── tableau                        # 可视化源文件
│   ├── dashboard.twbx             # Tableau 打包工作薄（含本地数据）
│   └── dashboard.png              # 最终大盘全景高清图
│
├── images                         # README 引用图片及过程图
│   ├── dashboard1.png             # 用户流量与留存监控板块图
│   ├── dashboard2.png             # 商品特征与热度分析板块图
│   └── funnel.png                 # 用户转化漏斗对称图
│
└── docs                           # 项目文档报告
    └── analysis_report.pdf        # 最终商业分析报告与运营策略 PPT 转 PDF
