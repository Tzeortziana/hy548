# Assignment 2: Kubernetes
## **Course:** CS-548 Cloud-native Software Architectures  
## **Name:** Entisa Tzeortziana Komoritsan
## **AM:** csdp1463 | **email:** tzeortziana@csd.uoc.gr



## Exercise 1

### Provide the YAML that runs a Pod with Nginx 1.29.5-alpine

**Manifest (`nginx-pod.yaml`):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.29.5-alpine
    ports:
    - containerPort: 80
      name: http
      protocol: TCP
```

### 1a. Install the manifest on Kubernetes and start the Pod

* **Command:** `kubectl apply -f nginx-pod.yaml`  
  <img src="images/screen1.png" alt="Description" width="500">


### 1b. Forward port 80 locally and answer the question

* **Command:** `kubectl port-forward demo-nginx 8080:80`  
    <img src="images/screen2.png" alt="Description" width="500">

* **What is the answer?**  
The answer is the default Nginx welcome page HTML. When accessing the forwarded port, the web server returns a page with the *Welcome to nginx!* and a message confirming the web server is successfully installed.

* **Validation Command (in a separate terminal and in browser):**  
    <img src="images/screen3.png" alt="Description" width="500">  
    <img src="images/screen4.png" alt="Description" width="500">


### 1c. See the logs of the running container

* **Command:** `kubectl logs demo-nginx`  
    <img src="images/screen5.png" alt="Description" width="500">


### 1d. Open a shell session inside the running container and change the first sentence of the default page to "Welcome to MY nginx!". Close the session. Validate the change.

* **Command:** `kubectl logs demo-nginx` : Opens an interactive shell inside the container    
* **Command:** `sed -i 's/Welcome to nginx!/Welcome to MY nginx!/g' /usr/share/nginx/html/index.html` : Changes the first sentence in the index.html file  
* **Command:** `curl [http://127.0.0.1:8080](http://127.0.0.1:8080)` : Validates the change locally  
  <img src="images/screen6.png" alt="Description" width="500">
  <img src="images/screen7.png" alt="Description" width="500">

### 1e. From your computer terminal (outside the container), download the default page locally and upload another one in its place. Validate the change.

* **Command:** `kubectl cp demo-nginx:/usr/share/nginx/html/index.html ./index.html` : Downloads the file from the Pod to the local machine    
    <img src="images/screen8.png" alt="Description" width="500">  
* **Command:** `kubectl cp ./index.html demo-nginx:/usr/share/nginx/html/index.html` : Uploads the new file back to the Pod, overwriting the old one    
* **Command:** `curl [http://127.0.0.1:8080](http://127.0.0.1:8080)` : Validates the change locally    
  <img src="images/screen9.png" alt="Description" width="500">


### 1f. Stop the Pod and remove the manifest from Kubernetes.

* **Command:** `kubectl delete pod demo-nginx`  


<hr style="border: 2px solid white;">  

## Exercise 2

### 2a. Provide a YAML that creates a Job using Ubuntu 24.04, which when started will run a script (defined in a ConfigMap) that will download the csd.uoc.gr site. Which command can you use to confirm that the Job completed successfully?

**Manifest (`job-download.yaml`):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: download-script
data:
  download.sh: |
    #!/bin/bash
    apt-get update && apt-get install -y wget
    mkdir -p /data
    cd /data
    wget -E -k -p https://www.csd.uoc.gr/

---
apiVersion: batch/v1
kind: Job
metadata:
  name: site-downloader-job
spec:
  template:
    spec:
      containers:
        - name: ubuntu
          image: ubuntu:24.04
          command: ["/bin/bash", "/scripts/download.sh"]
          volumeMounts:
            - name: script-volume
              mountPath: /scripts
      restartPolicy: Never
      volumes:
        - name: script-volume
          configMap:
            name: download-script
            defaultMode: 0777
```
* **Command:** `kubectl apply -f job-download.yaml`: Apply the manifest to create the ConfigMap and start the Job  
    <img src="images/screen11.png" alt="Description" width="500">  
* The primary command to confirm success is: `kubectl get jobs` Under the COMPLETIONS column, a successful job will show 1/1.  
   <img src="images/screen12.png" alt="Description" width="500"> 

* Since a Job creates a Pod to do the actual work, we can use `kubectl get pods`. For a Job, we are looking for the STATUS to change from Running or ContainerCreating to Completed.

* `kubectl describe pod site-downloader-job-vhm69`: It retrieves detailed information about a resource, including its configuration, status, and its Events.  
    <img src="images/screen13.png" alt="Description" width="500"> 



### 2b. Extend the previous YAML with an Nginx Pod, a CronJob that will refresh the content every night at 2:15, as well as a volume so that the Nginx Pod will show the content downloaded by the Jobs instead of the default page. Briefly describe how data is communicated between containers.

**Manifest (`job-download.yaml`):**
```yaml
# Storage (persistant)

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: site-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
# Scheduling (refresh at 2:15 AM)

apiVersion: batch/v1
kind: CronJob
metadata:
  name: site-refresh
spec:
  schedule: "15 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: ubuntu-downloader
              image: ubuntu:24.04
              command: ["/bin/bash", "/scripts/download.sh"]
              volumeMounts:
                - name: script-volume
                  mountPath: /scripts
                - name: web-site-storage
                  mountPath: /data
          restartPolicy: OnFailure
          volumes:
            - name: script-volume
              configMap:
                name: download-script
                defaultMode: 0777
            - name: web-site-storage
              persistentVolumeClaim:
                claimName: site-pvc

---
# Nginx serving the shared data

apiVersion: v1
kind: Pod
metadata:
  name: nginx-server
spec:
  containers:
    - name: nginx
      image: nginx:1.29.5-alpine
      volumeMounts:
        - name: web-site-storage
          mountPath: /usr/share/nginx/html
  volumes:
    - name: web-site-storage
      persistentVolumeClaim:
        claimName: site-pvc

```
* **Command:** `kubectl apply -f exercise2b.yaml`: Applies the storage, the automation schedule, and the web server.  
    <img src="images/screen14.png" alt="Description" width="500">  

* **Command:** `kubectl create job --from=cronjob/site-refresh manual-init-run`: Used to manually trigger the scheduled task for immediate verification.  
    <img src="images/screen16.png" alt="Description" width="500">  

* **Command:** `kubectl port-forward nginx-server 8081:80`: Forwards the Nginx server locally to validate the content is being served from the shared volume. 
    <img src="images/screen15.png" alt="Description" width="500"> 

* **Description of Data Communication:**  
Data is communicated between containers using a shared PersistentVolumeClaim (PVC). While containers are isolated by default, a PVC acts as a durable storage bridge. In this architecture, the CronJob Pod (Producer) mounts the PVC to write the downloaded website data, and the Nginx Pod (Consumer) mounts the same PVC to serve that content. This ensures data persistence independently of the Pods' lifecycles.


### 2c. Extend the previous YAML with an Nginx Pod, a CronJob that will refresh the content every night at 2:15, as well as a volume so that the Nginx Pod will show the content downloaded by the Jobs instead of the default page. Briefly describe how data is communicated between containers.

**Manifest (`job-download.yaml`):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-web
  template:
    metadata:
      labels:
        app: nginx-web
    spec:
      initContainers:
        - name: install-and-download
          image: ubuntu:24.04
          command: ["/bin/bash", "/scripts/download.sh"]
          volumeMounts:
            - name: script-volume
              mountPath: /scripts
            - name: web-site-storage
              mountPath: /data
      containers:
        - name: nginx
          image: nginx:1.29.5-alpine
          volumeMounts:
            - name: web-site-storage
              mountPath: /usr/share/nginx/html

      volumes:
        - name: script-volume
          configMap:
            name: download-script
            defaultMode: 0777
        - name: web-site-storage
          persistentVolumeClaim:
           claimName: site-pvc
```
* **Command:** `kubectl apply -f exercise2c.yaml`  
    <img src="images/screen17.png" alt="Description" width="500">  

* **Validation:**  
    * **Command:** `kubectl get pods -w`  
    <img src="images/screen18.png" alt="Description" width="500">

    * **Command:** `kubectl logs nginx-deployment-6f7cc99988-8h7hr -c install-and-download`  
    <img src="images/screen19.png" alt="Description" width="500">

    * **Command:** `kubectl port-forward deployment/nginx-deployment 8082:80`  
    <img src="images/screen20.png" alt="Description" width="500">  
    <img src="images/screen21.png" alt="Description" width="500">  
