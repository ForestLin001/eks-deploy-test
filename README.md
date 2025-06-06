# EKS Microservices Example

This project demonstrates a Python (FastAPI) and Go (Gin) microservices architecture deployed to AWS EKS.

## Services

- `/python/` - FastAPI
- `/go/` - Gin
- `/python/call-go` - FastAPI calling Gin service

## Deployment

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/go-deployment.yaml
kubectl apply -f k8s/python-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

Ensure you build and push Docker images before applying.
