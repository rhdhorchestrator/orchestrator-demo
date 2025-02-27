---

# **Quarkus Serverless Workflow - End-to-End Setup Guide**

This guide will walk you through setting up a **Quarkus Serverless Workflow** using PostgreSQL. It includes installation steps, project setup, database configuration, and running a workflow.

---

## **1. Prerequisites**
Before getting started, install the required dependencies.

### **1.1 Install Java 17+**
#### **macOS (M1/M2) - Using Homebrew**
```sh
brew install openjdk@17
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
Verify installation:
```sh
java -version
```

#### **Fedora**
```sh
sudo dnf install java-17-openjdk-devel
```
Verify installation:
```sh
java -version
```

---

### **1.2 Install Maven**
#### **macOS (M1/M2)**
```sh
brew install maven
```

#### **Fedora**
```sh
sudo dnf install maven
```
Verify installation:
```sh
mvn -version
```

---

### **1.3 Install Quarkus CLI**
#### **macOS (M1/M2)**
```sh
brew install quarkus
```

#### **Fedora**
```sh
curl -Lo install.sh https://code.quarkus.io/install.sh && chmod +x install.sh && ./install.sh
```
Verify installation:
```sh
quarkus --version
```

---

### **1.4 Install `kn-workflow` CLI**
> **⚠️ The standard `kn` CLI installation did not work, so use this method instead.**

#### **For macOS (M1/M2) - Arm64**
```sh
export KN_IMAGE=registry.redhat.io/openshift-serverless-1/logic-kn-workflow-cli-artifacts-rhel8:1.33.0
podman pull $KN_IMAGE
KN_CONTAINER_ID=$(podman create $KN_IMAGE)
podman cp $KN_CONTAINER_ID:/usr/share/kn/macos_arm64/kn-workflow-macos-arm64.tar.gz .
tar xvzf kn-workflow-macos-arm64.tar.gz
mv kn kn-workflow
sudo mv kn-workflow /usr/local/bin/kn-workflow
chmod +x /usr/local/bin/kn-workflow
```

#### **For Fedora (x86_64)**
```sh
export KN_IMAGE=registry.redhat.io/openshift-serverless-1/logic-kn-workflow-cli-artifacts-rhel8:1.33.0
podman pull $KN_IMAGE
KN_CONTAINER_ID=$(podman create $KN_IMAGE)
podman cp $KN_CONTAINER_ID:/usr/share/kn/linux/kn-workflow-linux.tar.gz .
tar xvzf kn-workflow-linux.tar.gz
mv kn kn-workflow
sudo mv kn-workflow /usr/local/bin/kn-workflow
chmod +x /usr/local/bin/kn-workflow
```

Verify installation:
```sh
kn-workflow version
```

---

## **2. Create a New Quarkus Project**
Use the **Knative Workflow CLI** to scaffold a new Quarkus project:

```sh
kn-workflow quarkus create --name 00_new_project
```

Change directory:
```sh
cd 00_new_project
```

---

## **3. Set Up PostgreSQL Database**
### **Option 1: Using Homebrew (macOS)**
```sh
brew install postgresql
brew services start postgresql
```
Create a database and user:
```sh
psql postgres
CREATE DATABASE quarkusdb;
CREATE USER quarkus WITH ENCRYPTED PASSWORD 'quarkus';
GRANT ALL PRIVILEGES ON DATABASE quarkusdb TO quarkus;
\q
```

### **Option 2: Using Podman (macOS/Linux)**
```sh
podman run --name quarkusdb -e POSTGRES_USER=quarkus -e POSTGRES_PASSWORD=quarkus -e POSTGRES_DB=quarkusdb -p 5432:5432 -d docker.io/library/postgres:14
```

---

## **4. Configure Quarkus to Use PostgreSQL**
Edit `src/main/resources/application.properties`:
```properties
# Standard JDBC datasource
%dev.quarkus.datasource.db-kind=postgresql
%dev.quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.username=quarkus
%dev.quarkus.datasource.password=quarkus

# 🔹 Reactive PostgreSQL configuration (fixes errors)
%dev.quarkus.datasource.reactive.url=postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.reactive.username=quarkus
%dev.quarkus.datasource.reactive.password=quarkus

# Allow Hibernate to create tables automatically (for dev only)
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
%dev.quarkus.hibernate-orm.sql-load-script=no-file
```

---

## **5. Manually Create the `process_instances` Table**
> **Important:** If your workflow execution fails due to a missing table, create it manually:

```sh
psql -h localhost -U quarkus -d quarkusdb -c "
CREATE TABLE IF NOT EXISTS process_instances (
    id UUID PRIMARY KEY,
    process_id VARCHAR(255),
    state INT,
    data JSONB
);
"
```

---

## **6. Define a Simple Serverless Workflow**
Edit `src/main/resources/workflows/hello.sw.json`:

```json
{
  "id": "hello",
  "version": "1.0",
  "specVersion": "0.8.0",
  "name": "Hello World",
  "description": "Description",
  "start": "HelloWorld",
  "states": [
    {
      "name": "HelloWorld",
      "type": "inject",
      "data": {
        "message": "Hello World"
      },
      "end": true
    }
  ]
}
```

---

## **7. Start the Quarkus Application**
```sh
mvn quarkus:dev
```

You should see logs confirming the workflow execution:
```
Workflow data
{
  "message" : "Hello World"
}
```

---

## **8. Test the Workflow API**
### **8.1 Start the Workflow**
Run:
```sh
curl -X POST http://localhost:8080/hello
```

### **8.2 Check the Workflow Status**
```sh
curl -X GET http://localhost:8080/hello
```

---

## **9. Stopping the Services**
### **If Using Homebrew PostgreSQL**
```sh
brew services stop postgresql
```

### **If Using Podman PostgreSQL**
```sh
podman stop quarkusdb
podman rm quarkusdb
```

---

# **🎉 Success!**
Your **Quarkus Serverless Workflow** is now up and running!
