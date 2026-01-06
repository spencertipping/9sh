# Building 9sh
The 9sh project requires a specific build environment based on Alpine Linux to ensure static linking and correct dependency versions.


## Prerequisites
- Docker


## Build Instructions
1.  **Build the Docker image:**
    ```bash
    docker build -t 9sh-builder .
    ```

2.  **Run the build:**
    ```bash
    docker run --rm -v $(pwd):/work 9sh-builder make clean && make
    ```

3.  **Run the shell:**
    ```bash
    docker run --rm -it -v $(pwd):/work 9sh-builder ./9sh
    ```


## Development
You can also run an interactive shell inside the container for development:
```bash
docker run --rm -it -v $(pwd):/work 9sh-builder bash
```
