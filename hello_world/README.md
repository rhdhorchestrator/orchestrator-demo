### **🚀 End-to-End Guide: Setting Up a Quarkus Serverless Workflow with PostgreSQL**
This guide walks you through **installing Quarkus, setting up PostgreSQL (via Homebrew or Podman), configuring a serverless workflow, and verifying everything works**. It includes all necessary installation steps, database verification, and testing commands.

---

## **📌 Prerequisites**
Before getting started, ensure you have the following installed:

### **1️⃣ Install Required Tools (macOS M1/M2 & Fedora)**
**🔹 On macOS (M1/M2):**
```sh
brew install openjdk@17 maven quarkus
```
Add Java to your path:
```sh
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**🔹 On Fedora:**
```sh
sudo dnf install -y java-17-openjdk maven quarkus
```

---

## **📌 Setting Up PostgreSQL**
### **🔹 Option 1: Install PostgreSQL with Homebrew (macOS)**
```sh
brew install postgresql
brew services start postgresql
```
Initialize and create a database:
```sh
psql postgres
CREATE DATABASE quarkusdb;
CREATE USER quarkus WITH ENCRYPTED PASSWORD 'quarkus';
GRANT ALL PRIVILEGES ON DATABASE quarkusdb TO quarkus;
\q
```

### **🔹 Option 2: Run PostgreSQL in a Podman Container**
```sh
podman run --name postgres -e POSTGRES_DB=quarkusdb -e POSTGRES_USER=quarkus -e POSTGRES_PASSWORD=quarkus -p 5432:5432 -d docker.io/library/postgres:14
```
Check if PostgreSQL is running:
```sh
podman ps
```

---

## **📌 Installing and Configuring Knative Workflow CLI**
### **⚠️ Why this workaround?**
The standard installation of `kn` CLI didn’t work for macOS (M1/M2). Instead, we pull an **official Red Hat container**, extract the CLI, and move it manually.

1. **Start a container with the Knative Workflow CLI:**
   ```sh
   export KN_IMAGE=registry.redhat.io/openshift-serverless-1/logic-kn-workflow-cli-artifacts-rhel8:1.33.0
   podman run --name kn-cli -d $KN_IMAGE sleep 3600
   ```

2. **Extract the CLI from the running container:**
   ```sh
   KN_CONTAINER_ID=$(podman ps -q --filter "name=kn-cli")
   podman cp $KN_CONTAINER_ID:/usr/share/kn/macos_arm64/kn-workflow-macos-arm64.tar.gz .
   tar xvzf kn-workflow-macos-arm64.tar.gz
   mv kn kn-workflow
   ```

3. **Move it to your system and make it executable:**
   ```sh
   sudo mv kn-workflow /usr/local/bin/
   chmod +x /usr/local/bin/kn-workflow
   ```

Verify installation:
```sh
kn-workflow version
```

---

## **📌 Creating the Project Structure**
Generate a new Quarkus Serverless Workflow project:
```sh
kn-workflow quarkus create --name hello-world
cd hello-world
```

---

## **📌 Configuring Database in Quarkus**
Edit `src/main/resources/application.properties` to include:

```properties
# Standard JDBC datasource (already working)
%dev.quarkus.datasource.db-kind=postgresql
%dev.quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.username=quarkus
%dev.quarkus.datasource.password=quarkus

# Reactive PostgreSQL configuration (optional)
%dev.quarkus.datasource.reactive.url=postgresql://localhost:5432/quarkusdb
%dev.quarkus.datasource.reactive.username=quarkus
%dev.quarkus.datasource.reactive.password=quarkus

# Allow Hibernate to create tables automatically (for dev mode)
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
%dev.quarkus.hibernate-orm.sql-load-script=no-file
```

---

## **📌 Ensuring the `process_instances` Table Exists**
Before running the workflow, ensure the `process_instances` table exists:

```sh
psql -h localhost -U quarkus -d quarkusdb -c "\dt"
```

If the table does **not** exist, create it manually:
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

## **📌 Implementing the Serverless Workflow**
Replace `src/main/resources/workflows/hello.sw.json` with:

```json
{
  "id": "hello",
  "version": "1.0",
  "specVersion": "0.8.0",
  "name": "Hello World",
  "description": "A simple hello world workflow",
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

## **📌 Running the Workflow**
Start Quarkus in **development mode**:
```sh
mvn quarkus:dev
```

Check the logs to verify it's running:
```
Workflow data
{
  "message": "Hello World"
}
```

---

## **📌 Verifying Database Entries**
Ensure the workflow execution is saved in the database:

```sh
psql -h localhost -U quarkus -d quarkusdb -c "SELECT * FROM process_instances;"
```

Check if workflows are being stored:
```sh
psql -h localhost -U quarkus -d quarkusdb -c "SELECT COUNT(*) FROM process_instances;"
```

---

## **📌 Testing Commands**
Verify PostgreSQL is running:
```sh
pg_isready -h localhost -U quarkus
```

List all tables in the database:
```sh
psql -h localhost -U quarkus -d quarkusdb -c "\dt"
```

Check active Podman containers (if using Podman):
```sh
podman ps
```

---

## **🎉 Done! What's Next?**
- Modify `hello.sw.json` to add **more workflow logic**.
- Integrate **REST APIs** to trigger workflows dynamically.
- Deploy to **Kubernetes** or **OpenShift**.

---
