## 🔍 **Comandos de Verificación del Cluster**

### **1. Estado General del Cluster**
```bash
# Ver todos los pods en todos los namespaces
kubectl get pods --all-namespaces

# Ver estado de nodos
kubectl get nodes

# Ver información detallada del cluster
kubectl cluster-info
```

### **2. Verificar Jenkins Específicamente**
```bash
# Ver pods de Jenkins
kubectl get pods -n tools

# Ver servicios de Jenkins
kubectl get svc -n tools

# Ver Ingress de Jenkins
kubectl get ingress -n tools

# Ver logs de Jenkins
kubectl logs -n tools -l app.kubernetes.io/name=jenkins

# Describir el pod de Jenkins
kubectl describe pod -n tools -l app.kubernetes.io/name=jenkins
```

### **3. Verificar Grafana y Prometheus**
```bash
# Ver pods de monitoreo
kubectl get pods -n monitoring

# Ver servicios de monitoreo
kubectl get svc -n monitoring

# Ver Ingress de Grafana
kubectl get ingress -n monitoring
```

### **4. Verificar Recursos del Sistema**
```bash
# Ver uso de recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Ver eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

