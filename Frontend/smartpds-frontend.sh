

#!/bin/bash

# Default values
NAMESPACE="smartpds"
DEPLOYMENT_NAME="smartpds-notify"
IMAGE="svchaudhari/smartpds-notify:master-1"
REPLICAS=3
ENV_VAR_1="default-value-1"
ENV_VAR_2="default-value-2"
PORT=8084
SERVICE_PORT=$PORT
TARGET_PORT=$PORT
TERMINATION_GRACE_PERIOD=30
CONFIGMAP_DB="smart-db-config"
CONFIGMAP_HOST="pds-service-host"
SECRET_DB="db"
INIT_CONTAINER_ENABLED=false
DB_MIGRATION_ENABLED=false
GIT_SYNC_ENABLED=false
ENABLE_PROBES=false
MEMORY_REQUEST="256Mi"
CPU_REQUEST="250m"
MEMORY_LIMIT="512Mi"
CPU_LIMIT="500m"
DEPLOY_DB_VARS=false
EXTERNAL_ENV_FILE="/home/smartpds/k8s-smartpds/frontend/external-var-frontend.txt"  # Path to external file



# Function to print usage
usage() {
  echo "Usage: $0 [-n namespace] [-d deployment_name] [-i image] [-r replicas] [-e1 env_var_1] [-e2 env_var_2] [-p port] [-sp service_port] [-tp target_port] [-t termination_grace_period] [-c configmap_name] [-s secret_name] [-ep enable_probes] [-db deploy_db_vars]"
  exit 1
}

# Function to append environment variables from an external file

# Function to append environment variables from an external file
append_external_env_vars() {
  if [[ -f "$EXTERNAL_ENV_FILE" ]]; then
    while IFS= read -r line; do
      # Skip empty lines and lines starting with '#'
      if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        ENV_NAME=$(echo $line | cut -d '=' -f 1)
        ENV_VALUE=$(echo $line | cut -d '=' -f 2-)
        cat <<EOF >> ${DEPLOYMENT_NAME}-deployment.yaml
            - name: $ENV_NAME
              value: $ENV_VALUE
EOF
      fi
    done < "$EXTERNAL_ENV_FILE"
  else
    echo "External environment file '$EXTERNAL_ENV_FILE' not found."
  fi
}

# Parse command-line arguments
while getopts "n:d:i:r:e1:e2:p:sp:tp:t:c:s:ep:db:h" opt; do
  case $opt in
    n) NAMESPACE=$OPTARG ;;
    d) DEPLOYMENT_NAME=$OPTARG ;;
    i) IMAGE=$OPTARG ;;
    r) REPLICAS=$OPTARG ;;
    e1) ENV_VAR_1=$OPTARG ;;
    e2) ENV_VAR_2=$OPTARG ;;
    p) PORT=$OPTARG ;;
    sp) SERVICE_PORT=$OPTARG ;;
    tp) TARGET_PORT=$OPTARG ;;
    t) TERMINATION_GRACE_PERIOD=$OPTARG ;;
    c) CONFIGMAP_DB=$OPTARG ;;
    s) SECRET_DB=$OPTARG ;;
    ep) ENABLE_PROBES=$OPTARG ;;
    db) DEPLOY_DB_VARS=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Check if DEPLOY_DB_VARS is enabled
create_deployment_with_db_vars() {
  if [[ "$DEPLOY_DB_VARS" == "true" ]]; then
    echo "Appending database environment variables to the deployment file..."
    cat <<EOF >> ${DEPLOYMENT_NAME}-deployment.yaml
            - name: SPRING_DATASOURCE_URL
              valueFrom:
                configMapKeyRef:
                  key: db-url
                  name: $CONFIGMAP_DB
            - name: SPRING_DATASOURCE_USERNAME
              valueFrom:
                secretKeyRef:
                  key: username
                  name: $SECRET_DB
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: password
                  name: $SECRET_DB
EOF
  fi
}

 # Conditionally include probes
 create_deployment_with_probes() {
  if [[ "$ENABLE_PROBES" == "true" ]]; then
    cat <<EOF >> ${DEPLOYMENT_NAME}-deployment.yaml
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path:  /actuator/health
              port: $PORT
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 60
            successThreshold: 1
            timeoutSeconds: 3
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /actuator/health
              port: $PORT
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 3
EOF
  else
    echo "Probes are disabled. No probes configuration will be added to the deployment."
  fi
}



# Check if the deployment exists
EXISTING_DEPLOYMENT=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE --ignore-not-found)

if [[ -z "$EXISTING_DEPLOYMENT" ]]; then
  echo "Deployment '$DEPLOYMENT_NAME' does not exist. Creating a new deployment..."
else
  echo "Deployment '$DEPLOYMENT_NAME' already exists. Updating values..."
  kubectl set image deployment/$DEPLOYMENT_NAME $DEPLOYMENT_NAME=$IMAGE -n $NAMESPACE
  kubectl scale deployment/$DEPLOYMENT_NAME --replicas=$REPLICAS -n $NAMESPACE
  if [[ "$PROBES" == "true" ]]; then
    echo "Adding probes to the deployment..."
    create_deployment_with_probes
  exit 0
  fi
fi


# Create a new deployment YAML dynamically
cat <<EOF > ${DEPLOYMENT_NAME}-deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
  labels:
    app: $DEPLOYMENT_NAME
spec:
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
    type: RollingUpdate
  progressDeadlineSeconds: 600
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: $DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $DEPLOYMENT_NAME
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: $DEPLOYMENT_NAME
                topologyKey: kubernetes.io/hostname
              weight: 100
      terminationGracePeriodSeconds: 30
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      containers:
        - name: $DEPLOYMENT_NAME
          image: $IMAGE
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: $PORT
              name: http
              protocol: TCP
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          lifecycle:
            preStop:
              exec:
                command:
                  - sh
                  - -c
                  - sleep 10
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          env:
            - name: SERVER_CONTEXT_PATH
              value: $DEPLOYMENT_NAME
            - name: JAVA_OPTS
              value: "-Xmx384m -Xms256m"
EOF
append_external_env_vars
create_deployment_with_db_vars
create_deployment_with_probes
# Conditionally include init containers
if [[ "$INIT_CONTAINER_ENABLED" == "true" ]]; then
  if [[ "$DB_MIGRATION_ENABLED" == "true" ]]; then
    cat <<EOF >> ${DEPLOYMENT_NAME}-deployment.yaml
      initContainers:
      - name: db-migration
        image: upyoguddhp/$DEPLOYMENT_NAME-db:v1.2.2-3c2f8b1051-13
        imagePullPolicy: IfNotPresent
EOF
  elif [[ "$GIT_SYNC_ENABLED" == "true" ]]; then
    cat <<EOF >> ${DEPLOYMENT_NAME}-deployment.yaml
      initContainers:
      - name: git-sync
        image: k8s.gcr.io/git-sync:v3.1.1
        imagePullPolicy: IfNotPresent
        env:
        - name: GIT_SYNC_REPO
          value: https://github.com/upyoguddhp/upyog-mdms-data.git
        - name: GIT_SYNC_BRANCH
          value: master
EOF
  fi
fi

# Apply the new deployment
echo "Generated Deployment YAML:"
cat ${DEPLOYMENT_NAME}-deployment.yaml
yamllint ${DEPLOYMENT_NAME}-deployment.yaml
kubectl apply -f ${DEPLOYMENT_NAME}-deployment.yaml

if [[ $? -ne 0 ]]; then
  echo "Failed to create deployment. Exiting."
  exit 1
fi
rm -f ${DEPLOYMENT_NAME}-deployment.yaml
echo "New deployment '$DEPLOYMENT_NAME' created successfully."

# Check if the service exists
EXISTING_SERVICE=$(kubectl get service $SERVICE_NAME -n $NAMESPACE --ignore-not-found)

if [[ -z "$EXISTING_SERVICE" ]]; then
  echo "Service '$SERVICE_NAME' does not exist. Creating a new service..."

  # Create a new service YAML dynamically
  cat <<EOF > ${SERVICE_NAME}-service.yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app: $DEPLOYMENT_NAME
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: $PORT
    protocol: TCP
    targetPort: $PORT
  selector:
    app: $DEPLOYMENT_NAME
  sessionAffinity: None
  type: ClusterIP
EOF

  # Apply the new service
  kubectl apply -f ${SERVICE_NAME}-service.yaml
  echo "New service '$SERVICE_NAME' created successfully."
else
  echo "Service '$SERVICE_NAME' already exists. Updating the service..."

  # Update the service logic: delete and recreate the service with updated values
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app: $DEPLOYMENT_NAME
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: $PORT
    nodePort: 30003
    protocol: TCP
    targetPort: $PORT
  selector:
    app: $DEPLOYMENT_NAME
  sessionAffinity: None
  type: NodePort
EOF
  echo "Service '$SERVICE_NAME' updated successfully."
fi


