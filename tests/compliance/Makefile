# =============================================================================
# terraform-compliance Makefile
# =============================================================================
# 使用方法:
#   make help           - ヘルプを表示
#   make plan dev       - dev 環境の Terraform Plan を生成
#   make plan stg       - stg 環境の Terraform Plan を生成
#   make test dev       - dev 環境のコンプライアンステストを実行
#   make test-security  - セキュリティテストのみ実行
#
# 注: uvx を使用してインストール不要で実行します
# =============================================================================

# 設定
PLAN_FILE := tfplan.binary
PLAN_JSON := tfplan.json
FEATURES_DIR := features

# 環境引数を取得（plan, test の後の引数）
ENV := $(word 2,$(MAKECMDGOALS))

# 環境ディレクトリ
TERRAFORM_DIR := ../../envs/$(ENV)

# uvx で terraform-compliance を実行（インストール不要）
TC := uvx terraform-compliance

# カラー出力
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# 環境名をターゲットとして無視（エラー回避）
%:
	@:

.PHONY: help plan test test-security test-network test-tagging test-data-protection test-critical clean docker-test

# デフォルトターゲット
help:
	@echo ""
	@echo "$(GREEN)terraform-compliance コマンド$(NC)"
	@echo ""
	@echo "$(YELLOW)Plan 生成:$(NC)"
	@echo "  make plan dev             - dev 環境の Plan を生成"
	@echo "  make plan stg             - stg 環境の Plan を生成"
	@echo "  make plan prod            - prod 環境の Plan を生成"
	@echo ""
	@echo "$(YELLOW)テスト実行:$(NC)"
	@echo "  make test dev             - dev 環境のすべてのテストを実行"
	@echo "  make test-critical dev    - クリティカルなテストのみ実行"
	@echo "  make test-security dev    - セキュリティテストのみ実行"
	@echo "  make test-network dev     - ネットワークテストのみ実行"
	@echo "  make test-tagging dev     - タグテストのみ実行"
	@echo "  make test-data-protection dev - データ保護テストのみ実行"
	@echo "  make test-storage dev     - Storage 関連のみ実行"
	@echo "  make test-keyvault dev    - Key Vault 関連のみ実行"
	@echo ""
	@echo "$(YELLOW)Docker:$(NC)"
	@echo "  make docker-test dev      - Docker でテストを実行"
	@echo ""
	@echo "$(YELLOW)クリーンアップ:$(NC)"
	@echo "  make clean dev            - 生成されたファイルを削除"
	@echo ""
	@echo "$(YELLOW)注: 環境名（dev/stg/prod）は必須です$(NC)"
	@echo ""

# 環境引数の必須チェック
_check_env:
	@if [ -z "$(ENV)" ]; then \
		echo "$(RED)エラー: 環境名を指定してください$(NC)"; \
		echo "$(YELLOW)例: make plan dev$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(TERRAFORM_DIR)" ]; then \
		echo "$(RED)エラー: 環境ディレクトリが見つかりません: $(TERRAFORM_DIR)$(NC)"; \
		exit 1; \
	fi

# Terraform Plan の生成
plan: _check_env
	@echo "$(GREEN)[$(ENV)] Terraform Plan を生成中...$(NC)"
	cd $(TERRAFORM_DIR) && \
		terraform init -upgrade && \
		terraform plan -out=$(PLAN_FILE) && \
		terraform show -json $(PLAN_FILE) > $(PLAN_JSON)
	@echo "$(GREEN)[$(ENV)] Plan 生成完了: $(TERRAFORM_DIR)/$(PLAN_JSON)$(NC)"

# Plan ファイルの存在確認
_check_plan: _check_env
	@if [ ! -f "$(TERRAFORM_DIR)/$(PLAN_JSON)" ]; then \
		echo "$(RED)エラー: $(TERRAFORM_DIR)/$(PLAN_JSON) が見つかりません$(NC)"; \
		echo "$(YELLOW)先に 'make plan $(ENV)' を実行してください$(NC)"; \
		exit 1; \
	fi

# すべてのテストを実行
test: _check_plan
	@echo "$(GREEN)[$(ENV)] すべてのコンプライアンステストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON)

# クリティカルなテストのみ実行
test-critical: _check_plan
	@echo "$(GREEN)[$(ENV)] クリティカルなコンプライアンステストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --tags @critical

# セキュリティテストのみ実行
test-security: _check_plan
	@echo "$(GREEN)[$(ENV)] セキュリティテストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR)/security -p $(TERRAFORM_DIR)/$(PLAN_JSON)

# ネットワークテストのみ実行
test-network: _check_plan
	@echo "$(GREEN)[$(ENV)] ネットワークテストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR)/network -p $(TERRAFORM_DIR)/$(PLAN_JSON)

# タグテストのみ実行
test-tagging: _check_plan
	@echo "$(GREEN)[$(ENV)] タグテストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR)/tagging -p $(TERRAFORM_DIR)/$(PLAN_JSON)

# データ保護テストのみ実行
test-data-protection: _check_plan
	@echo "$(GREEN)[$(ENV)] データ保護テストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR)/data-protection -p $(TERRAFORM_DIR)/$(PLAN_JSON)

# Storage テストのみ実行
test-storage: _check_plan
	@echo "$(GREEN)[$(ENV)] Storage テストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --tags @storage

# Key Vault テストのみ実行
test-keyvault: _check_plan
	@echo "$(GREEN)[$(ENV)] Key Vault テストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --tags @keyvault

# Database テストのみ実行
test-database: _check_plan
	@echo "$(GREEN)[$(ENV)] Database テストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --tags @database

# Container テストのみ実行
test-container: _check_plan
	@echo "$(GREEN)[$(ENV)] Container テストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --tags @container

# Docker でテストを実行
docker-test: _check_plan
	@echo "$(GREEN)[$(ENV)] Docker でコンプライアンステストを実行中...$(NC)"
	docker run --rm \
		-v $(PWD)/$(FEATURES_DIR):/features \
		-v $(PWD)/$(TERRAFORM_DIR):/plan \
		eerkunt/terraform-compliance \
		-f /features \
		-p /plan/$(PLAN_JSON)

# Plan ファイルと生成ファイルを削除
clean: _check_env
	@echo "$(YELLOW)[$(ENV)] 生成されたファイルを削除中...$(NC)"
	rm -f $(TERRAFORM_DIR)/$(PLAN_FILE) $(TERRAFORM_DIR)/$(PLAN_JSON)
	@echo "$(GREEN)[$(ENV)] クリーンアップ完了!$(NC)"

# CI/CD 用: Plan 生成からテストまで一括実行
ci: plan test
	@echo "$(GREEN)[$(ENV)] CI/CD パイプライン完了!$(NC)"

# 詳細出力でテスト実行
test-verbose: _check_plan
	@echo "$(GREEN)[$(ENV)] 詳細モードでテストを実行中...$(NC)"
	$(TC) -f $(FEATURES_DIR) -p $(TERRAFORM_DIR)/$(PLAN_JSON) --no-failure
