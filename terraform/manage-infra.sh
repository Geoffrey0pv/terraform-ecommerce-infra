#!/bin/bash

# Script para manejar la infraestructura GKE

case "$1" in
  "start")
    echo "🚀 Iniciando infraestructura completa..."
    sed -i 's/gke_node_count = 0/gke_node_count = 2/' terraform.tfvars
    terraform apply -auto-approve
    echo "✅ Infraestructura creada. Configurando kubectl..."
    gcloud container clusters get-credentials ecommerce-cluster --region us-central1
    echo "🎯 Usa './manage-infra.sh test' para probar el clúster"
    ;;
  "pause")
    echo "⏸️  Pausando nodos (solo clúster)..."
    sed -i 's/gke_node_count = 2/gke_node_count = 0/' terraform.tfvars
    terraform apply -auto-approve
    ;;
  "stop")
    echo "🛑 Destruyendo toda la infraestructura..."
    terraform destroy -auto-approve
    ;;
  "status")
    echo "📊 Estado actual de Terraform:"
    terraform show | grep -E "(name|status|machine_type|node_count)"
    echo ""
    echo "📊 Estado del clúster GKE:"
    kubectl get nodes 2>/dev/null || echo "❌ Clúster no accesible o no existe"
    ;;
  "test")
    echo "🧪 Probando el clúster GKE..."
    echo ""
    echo "📋 Nodos disponibles:"
    kubectl get nodes -o wide
    echo ""
    echo "📦 Namespaces:"
    kubectl get namespaces
    echo ""
    echo "🏃 Pods del sistema:"
    kubectl get pods -n kube-system
    echo ""
    echo "🎯 Creando pod de prueba..."
    kubectl run nginx-test --image=nginx --port=80 --restart=Never
    sleep 10
    echo ""
    echo "✅ Estado del pod de prueba:"
    kubectl get pod nginx-test
    kubectl describe pod nginx-test | tail -10
    ;;
  "logs")
    echo "📜 Selecciona qué logs ver:"
    echo "1) Logs del sistema (kube-system)"
    echo "2) Logs de pods de aplicación"
    echo "3) Logs del pod de prueba nginx"
    echo "4) Logs de eventos del clúster"
    read -p "Opción (1-4): " option
    
    case $option in
      1)
        echo "📜 Logs de pods del sistema:"
        kubectl get pods -n kube-system
        read -p "Introduce el nombre del pod: " pod_name
        kubectl logs -n kube-system $pod_name
        ;;
      2)
        echo "📜 Pods en namespace default:"
        kubectl get pods
        read -p "Introduce el nombre del pod: " pod_name
        kubectl logs $pod_name
        ;;
      3)
        echo "📜 Logs del pod de prueba nginx:"
        kubectl logs nginx-test 2>/dev/null || echo "❌ Pod nginx-test no existe. Ejecuta './manage-infra.sh test' primero"
        ;;
      4)
        echo "📜 Eventos recientes del clúster:"
        kubectl get events --sort-by='.lastTimestamp' | tail -20
        ;;
      *)
        echo "❌ Opción inválida"
        ;;
    esac
    ;;
  "connect")
    echo "🔌 Conectando kubectl al clúster..."
    gcloud container clusters get-credentials ecommerce-cluster --region us-central1
    echo "✅ kubectl configurado. Puedes usar comandos kubectl ahora"
    ;;
  "dashboard")
    echo "📊 Iniciando dashboard de Kubernetes..."
    echo "🔧 Instalando dashboard..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    echo "🔑 Creando usuario admin..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
    echo "🎯 Generando token de acceso..."
    kubectl -n kubernetes-dashboard create token admin-user
    echo ""
    echo "🌐 Ejecuta en otra terminal:"
    echo "kubectl proxy"
    echo ""
    echo "📱 Luego abre: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    ;;
  "cleanup")
    echo "🧹 Limpiando recursos de prueba..."
    kubectl delete pod nginx-test 2>/dev/null || echo "Pod nginx-test no existe"
    echo "✅ Limpieza completada"
    ;;
  "monitor")
    echo "📊 Monitor en tiempo real del clúster..."
    echo "Presiona Ctrl+C para salir"
    watch -n 5 'echo "=== NODOS ===" && kubectl get nodes && echo -e "\n=== PODS ===" && kubectl get pods --all-namespaces && echo -e "\n=== RECURSOS ===" && kubectl top nodes 2>/dev/null'
    ;;
  *)
    echo "🎛️  Gestor de Infraestructura GKE"
    echo ""
    echo "Uso: $0 {comando}"
    echo ""
    echo "📋 Gestión de infraestructura:"
    echo "  start     - Crear/iniciar infraestructura completa"
    echo "  pause     - Pausar nodos (mantener clúster)"
    echo "  stop      - Destruir todo"
    echo "  status    - Ver estado actual"
    echo ""
    echo "🧪 Testing y monitoreo:"
    echo "  test      - Probar el clúster con pod nginx"
    echo "  logs      - Ver logs de pods y sistema"
    echo "  connect   - Configurar kubectl"
    echo "  dashboard - Instalar y acceder al dashboard web"
    echo "  monitor   - Monitor en tiempo real"
    echo "  cleanup   - Limpiar recursos de prueba"
    echo ""
    echo "💡 Ejemplo de flujo:"
    echo "  ./manage-infra.sh start"
    echo "  ./manage-infra.sh test"
    echo "  ./manage-infra.sh logs"
    echo "  ./manage-infra.sh cleanup"
    echo "  ./manage-infra.sh pause"
    ;;
esac