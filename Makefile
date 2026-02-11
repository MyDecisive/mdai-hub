CHART_VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
REPO_NAME := $(shell basename -s .git `git config --get remote.origin.url`)

# Check if Kubernetes is installed and check version
check_kubernetes_version: KUBERNETES_VERSION_MIN := 1.24
check_kubernetes_version:
	@echo "🔍 Checking Kubernetes version..."
	@K8S_VERSION=$$(kubectl version 2>/dev/null | grep Server | awk '{print $$3}' | sed 's/^v//'); \
	if [ -z "$$K8S_VERSION" ]; then \
		echo "❌ Error: Unable to fetch Kubernetes version. Is your cluster running and accessible?"; \
		exit 1; \
	fi; \
    if [ "$$(printf '%s\n' "$(KUBERNETES_VERSION_MIN)" "$$K8S_VERSION" | sort -V | head -n1)" = "$(KUBERNETES_VERSION_MIN)" ]; then \
      echo "✅ Kubernetes version ($$K8S_VERSION) is sufficient."; \
    else \
      echo "❌ Kubernetes version ($$K8S_VERSION) is too old. Required: $(KUBERNETES_VERSION_MIN)."; \
      exit 1; \
    fi

# Check if EKS Cluster is running
check_eks_cluster: EKS_CLUSTER_NAME ?= eks
check_eks_cluster: EKS_REGION ?= us-east-1
check_eks_cluster:
	@echo "🔍 Checking if EKS cluster is running..."
	@aws eks describe-cluster --name $(EKS_CLUSTER_NAME) --region $(EKS_REGION) >/dev/null 2>&1
	@if [ $$? -eq 0 ]; then \
		echo "✅ EKS Cluster $(EKS_CLUSTER_NAME) is running."; \
	else \
		echo "❌ Error: EKS Cluster $(EKS_CLUSTER_NAME) is not running."; \
		exit 1; \
	fi

# Check if Prometheus Operator is installed and check version
check_prometheus_operator_version: PROMETHEUS_OPERATOR_VERSION_MIN := 0.71.2
check_prometheus_operator_version:
	@echo "🔍 Checking Prometheus Operator version..."
	@PROMETHEUS_OPERATOR_VERSION=$$(kubectl get crd prometheuses.monitoring.coreos.com -o jsonpath='{.metadata.annotations.operator\.prometheus\.io/version}' 2>/dev/null || echo "") && \
	if [ -z "$$PROMETHEUS_OPERATOR_VERSION" ]; then \
		echo "ℹ️ Prometheus Operator is not installed."; \
	elif [ "$$(printf '%s\n' "$(PROMETHEUS_OPERATOR_VERSION_MIN)" "$$PROMETHEUS_OPERATOR_VERSION" | sort -V | head -n1)" = "$(PROMETHEUS_OPERATOR_VERSION_MIN)" ]; then \
		echo "✅ Prometheus Operator version ($$PROMETHEUS_OPERATOR_VERSION) is compatible."; \
	else \
		echo "❌ Prometheus Operator version ($$PROMETHEUS_OPERATOR_VERSION) is incompatible. Minimum required version is $(PROMETHEUS_OPERATOR_VERSION_MIN)."; \
		exit 1; \
	fi

# Check if OTEL Operator is installed and check version
check_otel_operator_version: OTEL_OPERATOR_VERSION_MIN := 0.117.0
check_otel_operator_version:
	@echo "🔍 Checking OTEL Operator version..."
	@OTEL_OPERATOR_VERSION=$$(kubectl get deployments --all-namespaces -o jsonpath='{range .items[?(@.metadata.name=="opentelemetry-operator")]}{.spec.template.spec.containers[0].image}{"\n"}{end}' | tr -d '\n' | grep -v '^$$' | cut -d':' -f2) && \
	if [ -z "$$OTEL_OPERATOR_VERSION" ]; then \
		echo "ℹ️ OTEL Operator is not installed."; \
	elif [ "$$(printf '%s\n' "$(OTEL_OPERATOR_VERSION_MIN)" "$$OTEL_OPERATOR_VERSION" | sort -V | head -n1)" = "$(OTEL_OPERATOR_VERSION_MIN)" ]; then \
		echo "✅ OTEL Operator version ($$OTEL_OPERATOR_VERSION) is compatible."; \
	else \
		echo "❌ OTEL Operator version ($$OTEL_OPERATOR_VERSION) is incompatible. Minimum required version is $(OTEL_OPERATOR_VERSION_MIN)."; \
		exit 1; \
	fi

# Check if Cert Manager is installed and check version
check_cert_manager_version: CERT_MANAGER_VERSION_MIN := 1.10.1
check_cert_manager_version:
	@echo "🔍 Checking Cert Manager version..."
	@CERT_MANAGER_VERSION=$$(kubectl get crd clusterissuers.cert-manager.io -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}' 2>/dev/null | tr -d '\n' | grep -v '^$$' | sed 's/^v//'); \
	if [ -z "$$CERT_MANAGER_VERSION" ]; then \
		echo "❌ Cert Manager is not installed."; \
		exit 1; \
	elif [ "$$(printf '%s\n' "$(CERT_MANAGER_VERSION_MIN)" "$$CERT_MANAGER_VERSION" | sort -V | head -n1)" = "$(CERT_MANAGER_VERSION_MIN)" ]; then \
		echo "✅ Cert Manager version ($$CERT_MANAGER_VERSION) is compatible."; \
	else \
		echo "❌ Cert Manager version ($$CERT_MANAGER_VERSION) is incompatible. Minimum required version is $(CERT_MANAGER_VERSION_MIN)."; \
	fi

# Run all preflight checks
preflight_check:
	@echo "🛫 Running preflight checks..."
	@ERRORS=0; \
	$(MAKE) check_kubernetes_version || ERRORS=1; \
	if [ -z "$$SKIP_EKS" ]; then \
		$(MAKE) check_eks_cluster || ERRORS=1; \
	fi; \
	$(MAKE) check_prometheus_operator_version || ERRORS=1; \
	$(MAKE) check_otel_operator_version || ERRORS=1; \
	$(MAKE) check_cert_manager_version || ERRORS=1; \
	if [ $$ERRORS -ne 0 ]; then \
		echo "❌ Preflight checks failed."; \
		exit 1; \
	else \
		echo "✅ All preflight checks passed."; \
	fi

# Install the Helm chart
install_helm_chart: preflight_check
install_helm_chart: HELM_CHART_PATH := .
install_helm_chart: HELM_RELEASE_NAME := mdai-hub
install_helm_chart: HELM_NAMESPACE ?= mdai
install_helm_chart: CREATE_NAMESPACE_FLAG := $(if $(CREATE_NAMESPACE),--create-namespace,)
install_helm_chart:
	@echo "Installing Helm chart..."
	@helm upgrade --install $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) --namespace $(HELM_NAMESPACE) $(CREATE_NAMESPACE_FLAG) --values values.yaml

install: install_helm_chart

# Uninstall the Helm chart
uninstall_helm_chart: HELM_RELEASE_NAME := mdai-hub
uninstall_helm_chart: HELM_NAMESPACE ?= mdai
uninstall_helm_chart:
	@echo "Uninstalling Helm chart..."
	@helm uninstall $(HELM_RELEASE_NAME) --namespace $(HELM_NAMESPACE)

uninstall: uninstall_helm_chart

build_receipt: HELM_RELEASE_NAME := mdai-hub
build_receipt: HELM_NAMESPACE ?= mdai
build_receipt:
	@CMD=$$(command -v kubecolor >/dev/null 2>&1 && echo kubecolor || echo kubectl); \
	$$CMD get all -n $(HELM_NAMESPACE) -l app.kubernetes.io/instance=$(HELM_RELEASE_NAME)

helm-dependency-update:
	@echo "🔄 Updating helm dependencies..."
	@helm dependency update . --repository-config /dev/null > /dev/null

helm-package: helm-dependency-update
helm-package: CHART_DIR := ./
helm-package:
	@echo "📦 Packaging Helm chart..."
	@helm package -u --version $(CHART_VERSION) --app-version $(CHART_VERSION) $(CHART_DIR) > /dev/null

helm-publish: CHART_NAME := $(REPO_NAME)
helm-publish: CHART_REPO := git@github.com:MyDecisive/mdai-helm-charts.git
helm-publish: CHART_PACKAGE := $(CHART_NAME)-$(CHART_VERSION).tgz
helm-publish: BASE_BRANCH := gh-pages
helm-publish: TARGET_BRANCH := $(CHART_NAME)-v$(CHART_VERSION)
helm-publish: CLONE_DIR := $(shell mktemp -d /tmp/mdai-helm-charts.XXXXXX)
helm-publish: REPO_DIR := $(shell pwd)
helm-publish: helm-package
	@echo "🚀 Cloning $(CHART_REPO)..."
	@rm -rf $(CLONE_DIR)
	@git clone -q --branch $(BASE_BRANCH) $(CHART_REPO) $(CLONE_DIR)

	@echo "🌿 Creating branch $(TARGET_BRANCH) from $(BASE_BRANCH)..."
	@cd $(CLONE_DIR) && git checkout -q -b $(TARGET_BRANCH)

	@echo "📤 Copying and indexing chart..."
	@cd $(CLONE_DIR) && \
		rm -rf $(REPO_DIR)/charts && \
		helm repo index $(REPO_DIR) --merge index.yaml && \
		mv $(REPO_DIR)/$(CHART_PACKAGE) $(CLONE_DIR)/ && \
		mv $(REPO_DIR)/index.yaml $(CLONE_DIR)/

	@echo "🚀 Committing changes..."
	@cd $(CLONE_DIR) && \
		git add $(CHART_PACKAGE) index.yaml && \
		git commit -q -m "chore: publish $(CHART_PACKAGE)" && \
		git push -q origin $(TARGET_BRANCH) && \
		rm -rf $(CLONE_DIR)

	@echo "✅ Chart published"

.PHONY: check_kubernetes_version check_eks_cluster check_prometheus_operator_version check_otel_operator_version check_cert_manager_version preflight_check install_helm_chart uninstall_helm_chart install uninstall helm-dependency-update helm-package helm-publish
