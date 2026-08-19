// Purpose:
// On my GTX 1650 card, I have running into this error on running a somewhat
// compute-heavy kernel:
//		"GPU has fallen off the bus" (Xid 79) / cudaErrorUnknown(999)
// 
// One observation is that the GPU falls off when ramping-up beyond 15-17 W. This 
// is more of a standalone test to confirm this behaviour.
// Exceptions on the line of: cudaErrorInvalidDevice(101) are seen.
//
// Hypothesis being tested: 
// The failure is triggered by concurrent multi-threaded, multi-stream GPU usage with
// rapid alloc/free + stream create/destroy. THis could be causing a
// sudden idle -> full-load power transition across many SMs simultaneously, which my
// laptop's GPU (GTX 1650, no supplementary PCIe power connector) may not tolerate well.
//
// Build: Use C++20 - std::barrier, `g++` since CUDA 12.2 does not support beyond clang 16.*
//
//		nvcc -O2 -std=c++20 -ccbin $(which g++) -arch=sm_75 -o gpu_stress gpu_stress_repro.cu -lpthread
// 
// Usage:
//		./gpu_stress_repro [num_threads] [iterations] [elements_per_alloc] [work_reps]
//
// When running like this, there is no issue:
//		./gpu_stress 8 50 1000000 200
// Running with these parameters causes the issue:
//		 ./gpu_stress 16 2000 4000000 20000
//
// So far, my laptop is indicating that I need a new laptop. :(

#include <cuda_runtime.h>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

// Error check and logging with file and line combo
inline void cuda_check(cudaError_t err, const char* expr, const char* file, int line) {
    if (err != cudaSuccess) {
        fprintf(stderr, "%s:%d - CUDA failure: %s failed - %s (%d)\n",
                file, line, expr, cudaGetErrorString(err), static_cast<int>(err));
        std::fflush(stderr);
        throw std::runtime_error(std::string(file) + ":" + std::to_string(line) +
                                  " - CUDA failure: " + expr + " failed - " +
                                  cudaGetErrorString(err));
    }
}
#define CUDA_CHECK(expr) cuda_check((expr), #expr, __FILE__, __LINE__)

// ---------------------------------------------------------------------------
// RAII nonblocking stream wrapper
// ---------------------------------------------------------------------------
class Stream {
public:
    Stream() { CUDA_CHECK(cudaStreamCreateWithFlags(&stream_, cudaStreamNonBlocking)); }
    ~Stream() {
        if (stream_) {
            cudaStreamDestroy(stream_); // no throw in dtor
        }
    }

	// Disable copy
    Stream(const Stream&) = delete;
    Stream& operator=(const Stream&) = delete;
    cudaStream_t get() const noexcept { return stream_; }

private:
    cudaStream_t stream_ = nullptr;
};

// A kernel that burns real SM cycles (not memory-bandwidth-bound), so that
// many concurrent launches actually spike power draw rather than sit queued.
// This is deliberately compute-heavy per element.
__global__ void burn_kernel(float* data, int n, int work_reps) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n) return;
    float v = data[idx];
    for (int i = 0; i < work_reps; ++i) {
        v = v * 1.0000001f + 0.0000001f;
        v = __sinf(v) + __cosf(v);
    }
    data[idx] = v;
}

// Per-thread worker: repeatedly allocate, launch, sync, free, using its own
// nonblocking stream. All threads are released simultaneously via a barrier,
// each iteration to force a synchronized idle->burst transition
void worker(int thread_id, int iterations, int n_elements, int work_reps,
			std::barrier<>& sync_point, std::atomic<bool>& failed,
			std::atomic<int>& completed_iterations) {
	try {
		for (int iter = 0; iter < iterations && !failed.load(); ++iter) {
			// New stream each iteration on purpose: mirrors code that
			// constructs a Stream object per call site rather than reusing
			// a long-lived one. If churn itself is the trigger, this will
			// surface it; if not, this is still a valid concurrent-load test.
			Stream stream;

			float* d_ptr = nullptr;
			CUDA_CHECK(cudaMallocAsync( reinterpret_cast<void**>(&d_ptr),
										static_cast<size_t>(n_elements) * sizeof(float),
										stream.get()));

			// Barrier: every thread waits here until ALL threads have their
			// allocation ready, then everyone launches within the same
			// narrow window -> synchronized burst load across SMs.
			sync_point.arrive_and_wait();

			int block = 256;
			int grid = (n_elements + block - 1) / block;
			burn_kernel<<<grid, block, 0, stream.get()>>>(d_ptr, n_elements, work_reps);

			CUDA_CHECK(cudaGetLastError());
			CUDA_CHECK(cudaStreamSynchronize(stream.get()));
			CUDA_CHECK(cudaFreeAsync(d_ptr, stream.get()));
			CUDA_CHECK(cudaStreamSynchronize(stream.get()));

			completed_iterations.fetch_add(1);

			if (thread_id == 0 && iter % 5 == 0) {
				printf("[iter %d/%d] completed across all threads so far: %d\n",
						iter, iterations, completed_iterations.load());
				std::fflush(stdout);
			}
		}
	} catch (const std::exception& e) {
		failed.store(true);
		fprintf(stderr, "[thread %d] EXCEPTION: %s\n", thread_id, e.what());
		std::fflush(stderr);
	}
}

int main(int argc, char** argv) {
	int num_threads      = argc > 1 ? std::atoi(argv[1]) : 8;
	int iterations       = argc > 2 ? std::atoi(argv[2]) : 50;
	int n_elements       = argc > 3 ? std::atoi(argv[3]) : 1'000'000;
	int work_reps         = argc > 4 ? std::atoi(argv[4]) : 200;

	printf( "Config: threads=%d iterations=%d n_elements=%d work_reps=%d\n",
			num_threads, iterations, n_elements, work_reps);
	printf("Watch a second terminal with: nvidia-smi -l 1\n");
	printf("or:  nvidia-smi --query-gpu=timestamp,power.draw,temperature.gpu,pstate --format=csv -l 1\n\n");
	std::fflush(stdout);

	// Confirm device is healthy before starting.
	int device_count = 0;
	CUDA_CHECK(cudaGetDeviceCount(&device_count));
	if (device_count == 0) {
		fprintf(stderr, "No CUDA devices visible. Aborting before stress test.\n");
		return 1;
	}
	CUDA_CHECK(cudaSetDevice(0));
	CUDA_CHECK(cudaFree(0)); // force context init up front, outside the timed loop

	std::atomic<bool> failed{false};
	std::atomic<int> completed_iterations{0};
	std::barrier sync_point(num_threads);

	std::vector<std::thread> threads;
	threads.reserve(num_threads);

	auto start = std::chrono::steady_clock::now();

	for (int t = 0; t < num_threads; ++t) {
		threads.emplace_back(worker, t, iterations, n_elements, work_reps,
							 std::ref(sync_point), std::ref(failed),
							 std::ref(completed_iterations));
	}
	for (auto& th : threads) {
		th.join();
	}

	auto end = std::chrono::steady_clock::now();
	double secs = std::chrono::duration<double>(end - start).count();

	// Final health check.
	cudaError_t final_err = cudaGetLastError();
	int post_device_count = 0;
	cudaError_t enum_err = cudaGetDeviceCount(&post_device_count);

	printf("\n--- Summary ---\n");
	printf("Wall time: %.2fs\n", secs);
	printf("Total completed iterations across all threads: %d / %d\n",
		   completed_iterations.load(), num_threads * iterations);
	printf("failed flag: %s\n", failed.load() ? "TRUE (see stderr above)" : "false");
	printf("cudaGetLastError after join: %s\n", cudaGetErrorString(final_err));
	printf( "cudaGetDeviceCount after join: %s (count=%d)\n",
			cudaGetErrorString(enum_err), post_device_count);

	if (failed.load() || enum_err != cudaSuccess || post_device_count == 0) {
		printf("\n>>> REPRO LIKELY SUCCEEDED: GPU became unhealthy during/after the run.\n");
		printf(">>> Run `nvidia-smi` and `dmesg | tail -50` now to confirm Xid code.\n");
		return 1;
	}

	printf("\nNo failure detected at this thread/iteration count.\n");
	printf("Try increasing num_threads and/or work_reps to raise concurrent load,\n");
	printf("or increase iterations to test whether it's cumulative (e.g. VRAM/handle leak)\n");
	printf("rather than purely a power-transient trigger.\n");
	return 0;
}
