# Nginx Prometheus 
`quay.io/utilitywarehouse/nginx-prometheus`
## About
A build of Nginx with a 3rd party plugin, Virtual Traffic Status (VTS) which provides an instrumented deployment of Nginx on alpine.
* https://github.com/vozlt/nginx-module-vts
* http://nginx.org/en/docs/configure.html

## Running
you can run this image as a Docker container
```
docker pull quay.io/utilitywarehouse/nginx-prometheus:latest
docker run -it --rm -p 3000:80 -p 8080:8080 quay.io/utilitywarehouse/nginx-prometheus:latest
```

to get a list of releases checkout the releases section of the source repository or head on over to [quay.io](https://quay.io/repository/utilitywarehouse/nginx-prometheus?tab=tags)

## Configuring
usual Nginx stuff, mount your virtual hosts directory to `/etc/nginx/conf.d` and all configs will be loaded and instrumented, for example;
```
docker run -it --rm -p 3000:80 -p 8080:8080 -v my_confs:/etc/nginx/conf.d quay.io/utilitywarehouse/nginx-prometheus:latest
```

### Promethus and other stats scrapers
The instance will expose stats on the `8080` port, multiple formats are supported;
* json - `/status/format/json`
* html - `/status/format/html`
* jsonp - `/status/format/jsonp`
* prometheus- `/status/format/prometheus`

for more information on exposed metrics and use of the control endpoint please head over to https://github.com/vozlt/nginx-module-vts and read the manual/docs

## Kubernetes
Works well with kubernetes, see below for example config;
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
  annotations:
    prometheus.io/path: /status/format/prometheus
    prometheus.io/port: "8080"
    prometheus.io/scrape: "true"
spec:
  type: LoadBalancer
  loadBalancerIP: xxx.xxx.xxx.xxx
  externalTrafficPolicy: Local
  sessionAffinity: ClientIP
  selector:
    app: nginx-lb
  ports:
  - port: 80
    name: http
  - port: 8080
    name: prometheus
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: nginx-lb
  namespace: loadbalancers
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx-lb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-lb
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-lb
  template:
    metadata:
      labels:
        app: nginx-lb
    spec:
      terminationGracePeriodSeconds: 30
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - nginx-lb
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - name: nginx-lb
        image: quay.io/utilitywarehouse/nginx-prometheus:latest
        ports:
        - containerPort: 80
          name: http
        - containerPort: 8080
          name: prometheus
---
```