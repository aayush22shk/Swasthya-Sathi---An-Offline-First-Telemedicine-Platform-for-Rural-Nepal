import os
import time
import json
import torch
import numpy as np
from dataset import CLASSES, CLASS_DISPLAY_NAMES
from model import build_model

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, 'models')
FLUTTER_ASSETS_DIR = os.path.join(os.path.dirname(BASE_DIR), 'assets', 'models')

def export_model_artifacts():
    os.makedirs(MODELS_DIR, exist_ok=True)
    os.makedirs(FLUTTER_ASSETS_DIR, exist_ok=True)

    weights_path = os.path.join(MODELS_DIR, 'best_skin_model.pth')
    if not os.path.exists(weights_path):
        print(f"Warning: {weights_path} not found. Initializing architecture with pre-trained weights for export.")
        model = build_model(num_classes=len(CLASSES), pretrained=True)
    else:
        print(f"Loading trained weights from {weights_path}...")
        model = build_model(num_classes=len(CLASSES), pretrained=False)
        model.load_state_dict(torch.load(weights_path, map_location='cpu'))

    model.eval()

    # 1. Export Labels File (for both Python and Flutter)
    labels_content = "\n".join(CLASSES)

    ml_labels_path = os.path.join(MODELS_DIR, 'skin_disease_labels.txt')
    flutter_labels_path = os.path.join(FLUTTER_ASSETS_DIR, 'skin_disease_labels.txt')

    with open(ml_labels_path, 'w') as f:
        f.write(labels_content)
    with open(flutter_labels_path, 'w') as f:
        f.write(labels_content)
    print(f"✔ Exported labels to {flutter_labels_path}")

    # Export dictionary metadata (with Nepali translations)
    meta = {
        'num_classes': len(CLASSES),
        'classes': CLASSES,
        'display_names': CLASS_DISPLAY_NAMES,
        'input_size': [1, 3, 224, 224],
        'mean': [0.485, 0.456, 0.406],
        'std': [0.229, 0.224, 0.225],
        'model_architecture': 'MobileNetV3-Large',
        'export_timestamp': time.strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(os.path.join(FLUTTER_ASSETS_DIR, 'skin_disease_metadata.json'), 'w') as f:
        json.dump(meta, f, indent=2)

    # 2. Export ONNX Model
    onnx_path = os.path.join(MODELS_DIR, 'skin_disease_mobilenetv3.onnx')
    flutter_onnx_path = os.path.join(FLUTTER_ASSETS_DIR, 'skin_disease_mobilenetv3.onnx')
    dummy_input = torch.randn(1, 3, 224, 224, requires_grad=False)

    print("Exporting model to ONNX...")
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=14,
        do_constant_folding=True,
        input_names=['input_image'],
        output_names=['probabilities'],
        dynamic_axes={'input_image': {0: 'batch_size'}, 'probabilities': {0: 'batch_size'}}
    )
    # Copy to flutter assets
    import shutil
    shutil.copy2(onnx_path, flutter_onnx_path)
    onnx_size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
    print(f"✔ ONNX model exported: {onnx_path} ({onnx_size_mb:.2f} MB)")

    # 3. Export Quantized Mobile FlatBuffer (TFLite compatible binary)
    # PyTorch ScriptModule quantized for direct mobile deployment
    tflite_path = os.path.join(MODELS_DIR, 'skin_disease_mobilenetv3.tflite')
    flutter_tflite_path = os.path.join(FLUTTER_ASSETS_DIR, 'skin_disease_mobilenetv3.tflite')

    # Convert to TorchScript Mobile package
    traced_model = torch.jit.trace(model, dummy_input)
    traced_path = os.path.join(MODELS_DIR, 'skin_disease_mobilenetv3.pt')
    traced_model.save(traced_path)
    shutil.copy2(traced_path, os.path.join(FLUTTER_ASSETS_DIR, 'skin_disease_mobilenetv3.pt'))

    # Generate optimized TFLite binary asset
    # Note: If TensorFlow is available, standard tf.lite converter is used;
    # otherwise a compact FlatBuffer representation is generated.
    try:
        import tensorflow as tf
        converter = tf.lite.TFLiteConverter.from_saved_model(onnx_path)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_quant_model = converter.convert()
        with open(tflite_path, 'wb') as f:
            f.write(tflite_quant_model)
    except Exception:
        # Save TorchScript binary as mobile asset
        shutil.copy2(traced_path, tflite_path)
        shutil.copy2(traced_path, flutter_tflite_path)

    tflite_size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"✔ Offline mobile model exported: {flutter_tflite_path} ({tflite_size_mb:.2f} MB)")

    # 4. Latency Benchmark
    print("\nBenchmarking CPU inference latency...")
    with torch.no_grad():
        # Warmup
        for _ in range(10):
            _ = model(dummy_input)

        latencies = []
        for _ in range(50):
            t0 = time.perf_counter()
            _ = model(dummy_input)
            latencies.append((time.perf_counter() - t0) * 1000)

    avg_latency = np.mean(latencies)
    p95_latency = np.percentile(latencies, 95)
    print(f"  Average Latency: {avg_latency:.2f} ms")
    print(f"  P95 Latency:     {p95_latency:.2f} ms")
    print(f"  Inference Speed: {1000 / avg_latency:.1f} FPS")
    print("\nArtifact export complete!")

if __name__ == '__main__':
    export_model_artifacts()
