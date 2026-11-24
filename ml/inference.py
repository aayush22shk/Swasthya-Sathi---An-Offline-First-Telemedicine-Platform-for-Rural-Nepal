import os
import torch
import numpy as np
from PIL import Image
from dataset import (
    CLASSES, CLASS_DISPLAY_NAMES,
    get_transforms, is_skin_image
)
from model import build_model

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, 'models')

# Condition knowledge base with English and Nepali guidance
CLINICAL_KNOWLEDGE = {
    'acne': {
        'name': 'Acne Vulgaris',
        'nepali_name': 'डण्डीफोर (Acne)',
        'description': 'Common inflammatory condition of the sebaceous glands and hair follicles, producing comedones, papules, and pustules.',
        'symptoms': ['Pimples/zits', 'Blackheads/whiteheads', 'Red inflamed bumps', 'Oily skin'],
        'advice_en': 'Wash face gently twice daily with mild cleanser. Avoid picking or squeezing lesions to prevent scarring.',
        'advice_ne': 'दिनमा दुई पटक हल्का फेसवाशले मुख धुनुहोस्। दाग बस्नबाट जोगिन डण्डीफोर नकोट्याउनुहोस्।',
        'urgency': 'low'
    },
    'eczema': {
        'name': 'Eczema (Atopic / Contact Dermatitis)',
        'nepali_name': 'दाद/छाला चिलाउने (Eczema)',
        'description': 'Pruritic, inflammatory skin disease characterized by erythema, scaling, and lichenified skin patches.',
        'symptoms': ['Intense itching', 'Dry, sensitive skin', 'Red inflamed patches', 'Cracked skin'],
        'advice_en': 'Apply generous fragrance-free moisturizers immediately after bathing. Avoid harsh soaps and known contact allergens.',
        'advice_ne': 'नुहाएपछि तुरुन्तै मोइस्चराइजर क्रिम लगाउनुहोस्। कडा साबुन र एलर्जी गराउने वस्तुहरूबाट बच्नुहोस्।',
        'urgency': 'medium'
    },
    'psoriasis': {
        'name': 'Psoriasis (Plaque)',
        'nepali_name': 'सोरायसिस / सेतो कत्ला पर्ने रोग',
        'description': 'Chronic autoimmune condition accelerating skin cell turnover, causing thick, silvery-scaled erythematous plaques.',
        'symptoms': ['Silvery scaly plaques', 'Dry cracked skin that may bleed', 'Itching or burning sensation', 'Common on elbows/knees'],
        'advice_en': 'Keep skin hydrated with emollient ointments. Consult a dermatologist for topical corticosteroid or systemic therapies.',
        'advice_ne': 'छालालाई सुख्खा हुन नदिन मलम लगाउनुहोस्। विशेषज्ञ डाक्टरसँग परामर्श गरी उपयुक्त उपचार लिनुहोस्।',
        'urgency': 'medium'
    },
    'tinea_ringworm': {
        'name': 'Tinea / Ringworm (Fungal)',
        'nepali_name': 'दाद / लुतो (Ringworm)',
        'description': 'Superficial fungal infection (dermatophytosis) forming an annular red ring with clear central skin and raised borders.',
        'symptoms': ['Ring-shaped red rash', 'Itchy, scaly edge', 'Central clearing', 'Common in groin, body, or feet'],
        'advice_en': 'Keep affected areas clean and completely dry. Wear loose cotton clothing. Do not share towels or bedding.',
        'advice_ne': 'प्रभावित भागलाई सफा र सुक्खा राख्नुहोस्। खुकुलो सुतीको कपडा लगाउनुहोस् र अरूको तौलिया प्रयोग नगर्नुहोस्।',
        'urgency': 'medium'
    },
    'vitiligo': {
        'name': 'Vitiligo (Depigmentation)',
        'nepali_name': 'दुबी (Vitiligo)',
        'description': 'Autoimmune destruction of melanocytes causing sharply circumscribed milky-white patches of depigmented skin.',
        'symptoms': ['Patchy loss of skin pigment', 'Chalky white skin patches', 'Premature whitening of hair in affected areas'],
        'advice_en': 'Protect depigmented areas with broad-spectrum sunscreen to prevent sunburn. Non-contagious condition.',
        'advice_ne': 'घामबाट जोगिन सनस्क्रिन वा छाता प्रयोग गर्नुहोस्। यो रोग अरूलाई सर्दैन।',
        'urgency': 'low'
    },
    'impetigo': {
        'name': 'Impetigo (Bacterial Crust)',
        'nepali_name': 'पाकेको घाउ / खटिरा (Impetigo)',
        'description': 'Highly contagious superficial bacterial infection (Staph or Strep) characterized by honey-colored adherent crusts.',
        'symptoms': ['Honey-colored crusts', 'Red sores that pop and ooze', 'Common around mouth/nose in children'],
        'advice_en': 'Wash sores gently with antiseptic soap. Keep hands clean and avoid sharing towels. Requires medical evaluation for antibiotic therapy.',
        'advice_ne': 'घाउलाई सफा पानी र साबुनले सफा राख्नुहोस्। हात बारम्बार धुनुहोस् र डाक्टरसँग परामर्श गरी एन्टिबायोटिक लिनुहोस्।',
        'urgency': 'high'
    },
    'scabies': {
        'name': 'Scabies (Mite Infestation)',
        'nepali_name': 'लुतो (Scabies)',
        'description': 'Infestation by Sarcoptes scabiei mite causing intense nocturnal pruritus, burrows, and excoriated erythematous papules.',
        'symptoms': ['Intense itching especially at night', 'Thin, wavy burrows', 'Pimply rash between fingers and wrists'],
        'advice_en': 'All close contacts and family members must be treated simultaneously. Wash bedding and clothing in hot water.',
        'advice_ne': 'परिवारका सबै सदस्यले एकैपटक उपचार गर्नुपर्छ। ओछ्यान र लुगाहरू तातो पानीमा धोएर घाममा सुकाउनुहोस्।',
        'urgency': 'high'
    },
    'rosacea': {
        'name': 'Rosacea (Facial Erythema)',
        'nepali_name': 'अनुहार रातो हुने रोग (Rosacea)',
        'description': 'Chronic inflammatory facial condition causing persistent erythema, visible blood vessels (telangiectasia), and papules.',
        'symptoms': ['Facial flushing/blushing', 'Visible broken blood vessels', 'Swollen red bumps without blackheads'],
        'advice_en': 'Avoid known triggers: extreme sun, spicy food, hot beverages, and alcohol. Use gentle, non-irritating skincare.',
        'advice_ne': 'घाम, धेरै पिरो खानेकुरा र मदिराबाट बच्नुहोस्। अनुहारमा कडा केमिकल वा क्रिम नलगाउनुहोस्।',
        'urgency': 'low'
    },
    'herpes_zoster': {
        'name': 'Herpes Zoster (Shingles)',
        'nepali_name': 'जनैखटिरा (Shingles)',
        'description': 'Reactivation of the varicella-zoster virus causing painful, unilateral dermatomal clustered fluid-filled vesicles.',
        'symptoms': ['Pain, burning, or tingling on one side', 'Red rash with fluid-filled blisters', 'Follows nerve path / dermatome'],
        'advice_en': 'Seek urgent clinical evaluation within 72 hours for antiviral medication to minimize nerve pain risk.',
        'advice_ne': '७२ घण्टाभित्र तुरुन्तै स्वास्थ्य संस्था वा डाक्टरकहाँ जानुहोस् ता कि नशाको दुखाइ कम गर्न औषधि सुरु गर्न सकियोस्।',
        'urgency': 'critical'
    },
    'urticaria': {
        'name': 'Urticaria (Hives / Wheals)',
        'nepali_name': 'पित्त उठ्ने / डाबर (Hives)',
        'description': 'Transient, raised, erythematous or pale wheals caused by histamine release, usually with intense pruritus.',
        'symptoms': ['Raised itchy welts (wheals)', 'Red flare around pale center', 'Lesions appear and resolve within 24 hours'],
        'advice_en': 'Avoid known allergic triggers. Cool compresses help soothe itching. If accompanied by breathing difficulty or throat swelling, seek emergency care immediately.',
        'advice_ne': 'एलर्जी गराउने वस्तुबाट टाढा रहनुहोस्। यदि सास फेर्न गाह्रो भएमा वा घाँटी सुन्निएमा तुरुन्तै अस्पताल जानुहोस्।',
        'urgency': 'medium'
    },
    'normal_or_non_skin': {
        'name': 'Normal Skin / Non-Skin Object',
        'nepali_name': 'सामान्य छाला वा अन्य वस्तु',
        'description': 'No distinct pathological lesion detected, or the photograph represents unblemished skin or background surfaces.',
        'symptoms': ['No clear active rash or lesion identified'],
        'advice_en': 'Ensure the photograph is focused, well-lit, and taken close to the area of concern.',
        'advice_ne': 'कृपया राम्रो उज्यालोमा समस्या भएको छालाको स्पष्ट फोटो खिच्नुहोस्।',
        'urgency': 'low'
    }
}

class SkinInferenceEngine:
    """
    Offline inference engine for skin disease classification.
    """
    def __init__(self, model_path=None):
        if model_path is None:
            model_path = os.path.join(MODELS_DIR, 'best_skin_model.pth')

        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.transform = get_transforms(is_training=False)

        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model weights not found at {model_path}. Run train.py first.")

        self.model = build_model(num_classes=len(CLASSES), pretrained=False)
        self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()

    def predict(self, image_input):
        """
        Accepts PIL Image or file path. Returns structured clinical prediction.
        """
        if isinstance(image_input, str):
            if not os.path.exists(image_input):
                return {'error': f'Image file not found: {image_input}'}
            img = Image.open(image_input).convert('RGB')
        elif isinstance(image_input, Image.Image):
            img = image_input.convert('RGB')
        else:
            return {'error': 'Invalid image format provided.'}

        # 1. Skin Color Gamut & Resolution Filter
        if not is_skin_image(img, min_skin_ratio=0.18):
            return {
                'success': False,
                'is_rejected': True,
                'error_type': 'NON_SKIN_IMAGE',
                'message': 'No human skin lesion detected in photograph. Please capture a clear, well-lit photo of the affected skin area.',
                'message_ne': 'फोटोमा छालाको समस्या पहिचान हुन सकेन। कृपया राम्रो उज्यालोमा छालाको स्पष्ट फोटो खिच्नुहोस्।'
            }

        # 2. Preprocess & Forward Pass
        tensor = self.transform(img).unsqueeze(0).to(self.device)

        with torch.no_grad():
            logits = self.model(tensor)
            probs = torch.softmax(logits, dim=1).squeeze(0).cpu().numpy()

        # 3. Sort predictions
        top_indices = np.argsort(probs)[::-1]
        top1_idx = top_indices[0]
        top1_class = CLASSES[top1_idx]
        top1_conf = float(probs[top1_idx])

        # 4. Uncertainty Evaluation
        # High entropy or max confidence < 60% flags uncertainty
        entropy = float(-np.sum(probs * np.log(probs + 1e-9)))
        is_uncertain = (top1_conf < 0.60) or (entropy > 1.85)

        # 5. Compile Top-3 Differential Predictions
        top_predictions = []
        for i in range(min(3, len(CLASSES))):
            idx = top_indices[i]
            c_key = CLASSES[idx]
            info = CLINICAL_KNOWLEDGE.get(c_key, {})
            top_predictions.append({
                'class_key': c_key,
                'condition_name': info.get('name', c_key),
                'nepali_name': info.get('nepali_name', ''),
                'confidence': round(float(probs[idx]), 4),
                'confidence_pct': round(float(probs[idx]) * 100, 1)
            })

        top1_info = CLINICAL_KNOWLEDGE.get(top1_class, {})

        return {
            'success': True,
            'is_rejected': False,
            'predicted_class': top1_class,
            'condition_name': top1_info.get('name', top1_class),
            'nepali_name': top1_info.get('nepali_name', ''),
            'confidence': round(top1_conf, 4),
            'confidence_pct': round(top1_conf * 100, 1),
            'is_uncertain': is_uncertain,
            'uncertainty_reason': 'Low statistical confidence or ambiguous morphological presentation. Clinical correlation required.' if is_uncertain else None,
            'urgency_level': top1_info.get('urgency', 'medium'),
            'description': top1_info.get('description', ''),
            'symptoms': top1_info.get('symptoms', []),
            'clinical_advice_en': top1_info.get('advice_en', ''),
            'clinical_advice_ne': top1_info.get('advice_ne', ''),
            'top_predictions': top_predictions,
            'disclaimer': 'Educational AI preliminary screening. Does not replace in-person examination by a registered physician. Do not start prescription medications without a doctor.'
        }

if __name__ == '__main__':
    print("Testing SkinInferenceEngine...")
    try:
        engine = SkinInferenceEngine()
        # Test with dummy image
        test_img = Image.new('RGB', (224, 224), color=(200, 130, 100))
        res = engine.predict(test_img)
        print("Inference Result:", res)
    except Exception as e:
        print("Inference test note (needs trained weights first):", e)
