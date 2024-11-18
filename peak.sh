#!/bin/bash

# Name of the existing Docker image
image_name="my-node-app"  # Replace with your existing image name

# Generate a unique container name using a timestamp
container_name="my-container-$(date +%s)"

# Node.js arguments (customizable)
max_old_space_size=512 # Example value, in MB
max_semi_space_size=256  # Example value, in MB
# node_args="--max_old_space_size=$max_old_space_size --max_semi_space_size=$max_semi_space_size"
node_args="--max_semi_space_size=$max_semi_space_size"

# Specified memory limit for the container
memory_limit="8G"  # Example value, in GB

# Start time recording
start_time=$(date +%s)

# Run the container with Node.js arguments, in the background, and remove it when it stops
docker run --name $container_name --cpus=1 --rm -m $memory_limit $image_name node $node_args dist/cli.js &

# Wait a moment to ensure the container starts
sleep 2

# Print Node.js version inside the container
node_version=$(docker exec $container_name node -v)
echo "Node.js Version: $node_version"

# Monitor memory usage and calculate peak
peak_memory=0

while [ "$(docker ps -q -f name=$container_name)" ]; do
    current_memory=$(docker stats --no-stream --format "{{.MemUsage}}" $container_name | awk -F/ '{print $1}' | sed 's/[^0-9.]//g')

    # Check if current memory is higher than peak recorded
    if (( $(echo "$current_memory > $peak_memory" | bc -l) )); then
        peak_memory=$current_memory
    fi

    sleep 1
done

# Record the end time
end_time=$(date +%s)

# Calculate total execution time
total_time=$((end_time - start_time))

# Append results to a text file
log_file="container_results.txt"
echo "Container Name: $container_name" >> $log_file
echo "Node.js Version: $node_version" >> $log_file
echo "Peak Memory Usage: $peak_memory MB" >> $log_file
echo "Total Execution Time: $total_time seconds" >> $log_file
# echo "--max-old-space-size=$max_old_space_size" >> $log_file
echo "--max-semi-space-size=$max_semi_space_size" >> $log_file
echo "Specified Memory Limit: $memory_limit" >> $log_file
echo "------------------------" >> $log_file

# Output results to console as well
echo "Container Name: $container_name"
echo "Peak Memory Usage: $peak_memory MB"
echo "Total Execution Time: $total_time seconds"
echo "Arguments: --max-old-space-size=$max_old_space_size, --max-semi-space-size=$max_semi_space_size"
echo "Specified Memory Limit: $memory_limit"
