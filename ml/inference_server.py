"""
SwasthyaSathi Skin Disease Inference Server
============================================
Lightweight Flask HTTP server that loads the trained MobileNetV3 PyTorch model
and serves real on-device predictions via a REST API.

Runs alongside the Node.js backend. Called by the Flutter app when the phone
is on the same LAN as the development PC (the .tflite file needs proper export
for true offline use; this is the interim solution for real inference).

Usage:
    python inference_server.py

Endpoints:
    POST /predict   — Accepts multipart image upload, returns JSON predictions
    GET  /health    — Health check
    GET  /classes   — Returns all 11 class labels
"""

import os
import io
import sys
import time
import json
import logging
import traceback

import torch
import torch.nn.functional as F
import torchvision.transforms as T
from PIL import Image
from flask import Flask, request, jsonify

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR  = os.path.join(BASE_DIR, 'models')
MODEL_PATH  = os.path.join(MODELS_DIR, 'best_skin_model.pth')

# Add ml/ to sys.path so we can import local modules
sys.path.insert(0, BASE_DIR)
from dataset import CLASSES, CLASS_DISPLAY_NAMES, is_skin_image, get_transforms
from model   import build_model

# ── Flask app ─────────────────────────────────────────────────────────────────
app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
log = logging.getLogger('inference_server')

# ── Global model state ────────────────────────────────────────────────────────
MODEL        = None
TRANSFORM    = None
DEVICE       = torch.device('cpu')   # CPU-only for lightweight PC inference
MODEL_LOADED = False

CONFIDENCE_THRESHOLD  = 0.45    # Below this → uncertain
SKIN_REQUIRED_RATIO   = 0.15    # Minimum skin pixels fraction required

# Clinical knowledge base (urgency levels, Nepali names)
CLINICAL_INFO = {
    'acne':              {'nepali': 'डण्डीफोर', 'urgency': 'low'},
    'eczema':            {'nepali': 'दाद/छाला चिलाउने', 'urgency': 'medium'},
    'psoriasis':         {'nepali': 'सोरायसिस', 'urgency': 'medium'},
    'tinea_ringworm':    {'nepali': 'दाद / फङ्गल इन्फेक्सन', 'urgency': 'medium'},
    'vitiligo':          {'nepali': 'दुबी', 'urgency': 'low'},
    'impetigo':          {'nepali': 'पाकेको घाउ / खटिरा', 'urgency': 'high'},
    'scabies':           {'nepali': 'लुतो', 'urgency': 'high'},
    'rosacea':           {'nepali': 'अनुहार रातो हुने रोग', 'urgency': 'low'},
    'herpes_zoster':     {'nepali': 'जनैखटिरा', 'urgency': 'critical'},
    'urticaria':         {'nepali': 'पित्त उठ्ने / डाबर', 'urgency': 'medium'},
    'normal_or_non_skin':{'nepali': 'सामान्य छाला वा अन्य वस्तु', 'urgency': 'low'},
}


def load_model():
    """Loads the trained PyTorch model into memory once at startup."""
    global MODEL, TRANSFORM, MODEL_LOADED
    if MODEL_LOADED:
        return True
    try:
        if not os.path.exists(MODEL_PATH):
            log.error(f'Model file not found: {MODEL_PATH}')
            return False

        log.info(f'Loading model from {MODEL_PATH} ...')
        t0 = time.time()
        MODEL = build_model(num_classes=len(CLASSES), pretrained=False)
        state = torch.load(MODEL_PATH, map_location=DEVICE, weights_only=True)
        MODEL.load_state_dict(state)
        MODEL.eval()
        MODEL.to(DEVICE)
        TRANSFORM = get_transforms(is_training=False, image_size=224)
        elapsed = time.time() - t0
        log.info(f'Model loaded in {elapsed:.2f}s  |  Classes: {len(CLASSES)}  |  Device: {DEVICE}')
        MODEL_LOADED = True

        # Warmup
        dummy = torch.zeros(1, 3, 224, 224)
        with torch.no_grad():
            _ = MODEL(dummy)
        log.info('Warmup inference complete.')
        return True
    except Exception as e:
        log.error(f'Failed to load model: {e}')
        traceback.print_exc()
        return False


def predict_image(pil_image: Image.Image) -> dict:
    """
    Runs inference on a PIL Image.
    Returns a dict with:
        - top_predictions: list of {class_key, display_name, nepali_name, confidence, confidence_pct}
        - is_uncertain: bool
        - is_non_skin: bool
        - model_version: str
    """
    if not MODEL_LOADED:
        return {'error': 'Model not loaded'}

    # Skin presence check
    is_skin = is_skin_image(pil_image, min_skin_ratio=SKIN_REQUIRED_RATIO)

    # Preprocess
    tensor = TRANSFORM(pil_image.convert('RGB')).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        logits = MODEL(tensor)
        probs  = F.softmax(logits, dim=1).squeeze(0).cpu().tolist()

    # Sort by probability descending
    indexed = sorted(enumerate(probs), key=lambda x: x[1], reverse=True)
    top3    = indexed[:3]

    top_class_idx  = top3[0][0]
    top_class_key  = CLASSES[top_class_idx]
    top_confidence = top3[0][1]

    is_uncertain = top_confidence < CONFIDENCE_THRESHOLD or not is_skin

    top_predictions = []
    for idx, conf in top3:
        cls_key = CLASSES[idx]
        info    = CLINICAL_INFO.get(cls_key, {'nepali': cls_key, 'urgency': 'low'})
        top_predictions.append({
            'class_key':      cls_key,
            'display_name':   CLASS_DISPLAY_NAMES.get(cls_key, cls_key),
            'nepali_name':    info['nepali'],
            'confidence':     round(conf, 4),
            'confidence_pct': round(conf * 100, 2),
            'urgency':        info['urgency'],
        })

    return {
        'top_predictions':   top_predictions,
        'predicted_class':   top_class_key,
        'predicted_name':    CLASS_DISPLAY_NAMES.get(top_class_key, top_class_key),
        'confidence':        round(top_confidence, 4),
        'is_uncertain':      is_uncertain,
        'is_non_skin':       not is_skin,
        'model_version':     'mobilenetv3_nepal_v1',
        'inference_device':  str(DEVICE),
    }


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'model_loaded': MODEL_LOADED,
        'num_classes': len(CLASSES),
        'classes': CLASSES,
    })


@app.route('/classes', methods=['GET'])
def get_classes():
    return jsonify({'classes': CLASSES, 'display_names': CLASS_DISPLAY_NAMES})


@app.route('/predict', methods=['POST'])
def predict():
    """
    Accepts: multipart/form-data with field 'image'
    OR:      application/octet-stream raw image bytes
    Returns: JSON prediction result
    """
    t0 = time.time()

    # Read image bytes
    image_bytes = None
    if 'image' in request.files:
        image_bytes = request.files['image'].read()
    elif request.content_type and 'image' in request.content_type:
        image_bytes = request.data
    elif request.data:
        image_bytes = request.data

    if not image_bytes:
        return jsonify({'error': 'No image provided. Send multipart field "image" or raw bytes.'}), 400

    try:
        pil_image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    except Exception as e:
        return jsonify({'error': f'Could not decode image: {e}'}), 400

    result = predict_image(pil_image)

    if 'error' in result:
        return jsonify(result), 503

    elapsed_ms = round((time.time() - t0) * 1000, 1)
    result['inference_ms'] = elapsed_ms
    log.info(
        f"Predicted: {result['predicted_class']} ({result['confidence']*100:.1f}%)  "
        f"uncertain={result['is_uncertain']}  "
        f"non_skin={result['is_non_skin']}  "
        f"latency={elapsed_ms}ms"
    )
    return jsonify(result)


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == '__main__':
    PORT = int(os.environ.get('INFERENCE_PORT', 5001))
    log.info(f'SwasthyaSathi Inference Server starting on port {PORT}...')
    if not load_model():
        log.warning('Model could not be loaded — /predict will return 503 until resolved.')
    app.run(host='0.0.0.0', port=PORT, debug=False, threaded=True)
