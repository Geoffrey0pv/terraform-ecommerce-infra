# Configuración de Credenciales para Producción

## Pasos para configurar las credenciales de GCP

### 1. Crear Service Account

```bash
# Crear el service account
gcloud iam service-accounts create terraform-ecommerce-sa \
  --display-name="Terraform Ecommerce Service Account" \
  --description="Service Account para Terraform del proyecto ecommerce"

# Asignar roles necesarios
gcloud projects add-iam-policy-binding ecommerce-backend-1760307199 \
  --member="serviceAccount:terraform-ecommerce-sa@ecommerce-backend-1760307199.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding ecommerce-backend-1760307199 \
  --member="serviceAccount:terraform-ecommerce-sa@ecommerce-backend-1760307199.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding ecommerce-backend-1760307199 \
  --member="serviceAccount:terraform-ecommerce-sa@ecommerce-backend-1760307199.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Crear y descargar la clave
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account=terraform-ecommerce-sa@ecommerce-backend-1760307199.iam.gserviceaccount.com
```

### 2. Configurar Variable de Entorno

```bash
# Para uso local (desarrollo)
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/absoluta/a/terraform-sa-key.json"

# Para verificar que está configurado
echo $GOOGLE_APPLICATION_CREDENTIALS
```

### 3. Para CI/CD (GitHub Actions, GitLab CI, etc.)

En tu pipeline de CI/CD, configura la variable de entorno `GOOGLE_APPLICATION_CREDENTIALS` o usa el contenido del archivo JSON como secret.

**Ejemplo para GitHub Actions:**
```yaml
- name: Setup GCP credentials
  uses: google-github-actions/auth@v1
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```

### 4. Verificar configuración

```bash
# Verificar que las credenciales funcionan
gcloud auth list

# Probar con Terraform
terraform plan
```

## Notas de Seguridad

- ✅ **NUNCA** commitees el archivo `terraform-sa-key.json` al repositorio
- ✅ Agrega `*.json` al `.gitignore`
- ✅ Usa roles mínimos necesarios para el service account
- ✅ Rota las claves periódicamente
- ✅ Usa variables de entorno en lugar de hardcodear credenciales

## Comandos Terraform

```bash
# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy
```