# ============================================================
# DOCKERFILE — Instructions to build your app into a container
# Think of this like a recipe. Docker reads top to bottom.
# ============================================================

# STEP 1: Start with a base image
# We don't install Python from scratch — we use an official image
# "slim" means lightweight version (smaller size, faster download)
FROM python:3.12-slim

# STEP 2: Set working directory INSIDE the container
# All commands after this will run inside /app folder in the container
# It's like doing "cd /app" inside the container
WORKDIR /app

# STEP 3: Copy requirements.txt into the container FIRST
# Why first? Because Docker caches each step.
# If only your code changes (not requirements), Docker skips re-installing packages
# This makes builds much faster next time
COPY requirements.txt .

# STEP 4: Install the Python packages inside the container
# --no-cache-dir means don't store install cache (keeps image size small)
RUN pip install --no-cache-dir -r requirements.txt

# STEP 5: Copy ALL your app files into the container
# The dot (.) means "copy everything from current folder to /app in container"
COPY . .

# STEP 6: Tell Docker which port this app listens on
# This is just documentation — it doesn't actually open the port
# You open the port when you run: docker run -p 5000:5000
EXPOSE 5000

# STEP 7: The command to START the app when container runs
# We use gunicorn (not Flask dev server) because:
#   - Flask dev server is for development only
#   - gunicorn handles multiple requests at once (production ready)
# --workers 2 means 2 processes handling requests simultaneously
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
