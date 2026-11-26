#!/bin/bash
# ============================================================
# COMANDOS EJECUTADOS - Proyecto cicdtraining
# Universidad de Boyacá · 2026 · github.com/mafeopa
# ============================================================

# ─── ETAPA 1: CONFIGURACIÓN INICIAL GCLOUD ──────────────────
gcloud init
gcloud config set project cicdtraining-498421
gcloud config list

# ─── ETAPA 2: HABILITAR APIS ────────────────────────────────
gcloud services enable run.googleapis.com artifactregistry.googleapis.com iam.googleapis.com iamcredentials.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable aiplatform.googleapis.com --project=cicdtraining-498421

# ─── ETAPA 3: ARTIFACT REGISTRY ─────────────────────────────
gcloud artifacts repositories create mi-app --repository-format=docker --location=us-central1
gcloud artifacts repositories list

# ─── ETAPA 4: SERVICE ACCOUNT Y PERMISOS ────────────────────
gcloud iam service-accounts create github-actions-sa --display-name="GitHub Actions SA"

gcloud projects add-iam-policy-binding cicdtraining-498421 \
  --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding cicdtraining-498421 \
  --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding cicdtraining-498421 \
  --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding cicdtraining-498421 \
  --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# ─── ETAPA 5: WORKLOAD IDENTITY FEDERATION ──────────────────
# Obtener número del proyecto
gcloud projects describe cicdtraining-498421 --format="value(projectNumber)"
# Resultado: 622078306811

# Crear Identity Pool
gcloud iam workload-identity-pools create "github-pool" --location="global" --display-name="GitHub Pool"

# Crear Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" --location="global" --workload-identity-pool="github-pool" --display-name="GitHub Provider" --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" --attribute-condition="assertion.repository_owner=='mafeopa'" --issuer-uri="https://token.actions.githubusercontent.com"

# Actualizar condición del provider (más seguro)
gcloud iam workload-identity-pools providers update-oidc "github-provider" --location="global" --workload-identity-pool="github-pool" --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" --attribute-condition="assertion.repository_owner=='mafeopa'"

# Verificar provider
gcloud iam workload-identity-pools providers describe github-provider --location="global" --workload-identity-pool="github-pool" --format="yaml"

# Vincular Service Account al pool
gcloud iam service-accounts add-iam-policy-binding github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com --role="roles/iam.workloadIdentityUser" --member="principalSet://iam.googleapis.com/projects/622078306811/locations/global/workloadIdentityPools/github-pool/attribute.repository_owner/mafeopa"

# Obtener nombre completo del provider (para secreto en GitHub)
gcloud iam workload-identity-pools providers describe github-provider --location="global" --workload-identity-pool="github-pool" --format="value(name)"
# Resultado: projects/622078306811/locations/global/workloadIdentityPools/github-pool/providers/github-provider

# ─── ETAPA 6: ARTIFACT REGISTRY — PERMISOS EXPLÍCITOS ───────
gcloud artifacts repositories add-iam-policy-binding mi-app --location=us-central1 --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"

# ─── ETAPA 7: CLOUD RUN — ACCESO PÚBLICO ────────────────────
gcloud run services add-iam-policy-binding mi-app --region=us-central1 --project=cicdtraining-498421 --member="allUsers" --role="roles/run.invoker"

# Obtener URL del servicio
gcloud run services describe mi-app --region=us-central1 --project=cicdtraining-498421 --format="value(status.url)"

# Ver concurrencia configurada
gcloud run services describe mi-app --region=us-central1 --project=cicdtraining-498421 --format="value(spec.template.spec.containerConcurrency)"

# Ajustar concurrencia máxima
gcloud run services update mi-app --concurrency=1000 --region=us-central1

# ─── ETAPA 8: CLOUD MONITORING — DASHBOARD ──────────────────
# (Requiere archivo dashboard.json creado previamente)
gcloud monitoring dashboards create --config-from-file=dashboard.json --project=cicdtraining-498421
gcloud monitoring dashboards list --project=cicdtraining-498421

# ─── ETAPA 9: ALERTAS DE SLO ────────────────────────────────
# (Requiere archivos alert-errors.json, alert-latency.json, alert-availability.json)
gcloud monitoring policies create --policy-from-file=alert-errors.json --project=cicdtraining-498421
gcloud monitoring policies create --policy-from-file=alert-latency.json --project=cicdtraining-498421
gcloud monitoring policies create --policy-from-file=alert-availability.json --project=cicdtraining-498421

# Listar alertas creadas
gcloud monitoring policies list --project=cicdtraining-498421

# ─── ETAPA 10: CANAL DE NOTIFICACIÓN EMAIL ──────────────────
gcloud beta monitoring channels create --display-name="Email Maria" --type=email --channel-labels=email_address=mfochoa@uniboyaca.edu.co --project=cicdtraining-498421
# Resultado ID: 12416972205859688771

# Vincular canal a las 3 alertas
gcloud monitoring policies update 11182487088173636770 --set-notification-channels=12416972205859688771 --project=cicdtraining-498421
gcloud monitoring policies update 6022321838366663113 --set-notification-channels=12416972205859688771 --project=cicdtraining-498421
gcloud monitoring policies update 6022321838366666603 --set-notification-channels=12416972205859688771 --project=cicdtraining-498421

# ─── ETAPA 11: VERTEX AI — GEMINI ───────────────────────────
gcloud services enable aiplatform.googleapis.com --project=cicdtraining-498421

gcloud projects add-iam-policy-binding cicdtraining-498421 \
  --member="serviceAccount:github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# ─── ETAPA 12: LOGS Y DIAGNÓSTICO ───────────────────────────
# Ver logs de Cloud Run
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=mi-app" --limit=20 --project=cicdtraining-498421 --format="value(textPayload)"

# Listar cuentas autenticadas
gcloud auth list

# Ver configuración activa
gcloud config list

# ─── ETAPA 13: PRUEBAS DE CARGA CON K6 ──────────────────────
# Instalar k6 (Windows)
winget install k6 --source winget

# Verificar versión
k6 version

# Ejecutar test de carga
k6 run load-test.js

# Ejecutar con reporte JSON
k6 run --out json=resultado.json load-test.js

# ─── ETAPA 14: ENDPOINTS DEL SERVICIO PARA PRUEBAS ──────────
# URL base: https://mi-app-622078306811.us-central1.run.app

# Health check
# GET /

# Simular trabajo
# GET /api/work?ms=100
# GET /api/work?ms=300
# GET /api/work?ms=800

# Simular error
# GET /api/work?ms=100&fail=true

# Prueba de concurrencia interna
# GET /api/stress?connections=100&ms=200
# GET /api/stress?connections=3000&ms=200
# GET /api/stress?connections=3000&ms=5000

# Ver métricas Prometheus
# GET /metrics

# IA — Asistente SRE (PowerShell)
# Invoke-WebRequest -Uri "https://mi-app-622078306811.us-central1.run.app/api/ai/sre" -Method POST -ContentType "application/json" -Body '{"question": "El sistema tuvo 50 errores 500, que debo hacer?"}'

# IA — Análisis k6 (PowerShell)
# Invoke-WebRequest -Uri "https://mi-app-622078306811.us-central1.run.app/api/ai/analyze" -Method POST -ContentType "application/json" -Body '{"metrics": {}}'

# IA — Predicción SLO (PowerShell)
# Invoke-WebRequest -Uri "https://mi-app-622078306811.us-central1.run.app/api/ai/predict" -Method POST -ContentType "application/json" -Body '{"metrics_history": []}'

# ─── REFERENCIAS RÁPIDAS ─────────────────────────────────────
# Proyecto GCP:        cicdtraining-498421
# Número de proyecto:  622078306811
# Región:              us-central1
# Servicio Cloud Run:  mi-app
# Artifact Registry:   mi-app
# GitHub user:         mafeopa
# SA email:            github-actions-sa@cicdtraining-498421.iam.gserviceaccount.com
# WIF Provider:        projects/622078306811/locations/global/workloadIdentityPools/github-pool/providers/github-provider
# URL servicio:        https://mi-app-622078306811.us-central1.run.app
# Alerta errores:      11182487088173636770
# Alerta latencia:     6022321838366663113
# Alerta disponib.:    6022321838366666603
# Canal email:         12416972205859688771
