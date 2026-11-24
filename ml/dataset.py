import os
import random
import numpy as np
from PIL import Image
import torch
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as T

# Standard 11 classes (10 target skin conditions + 1 OOD background / non-skin)
CLASSES = [
    'acne',
    'eczema',
    'psoriasis',
    'tinea_ringworm',
    'vitiligo',
    'impetigo',
    'scabies',
    'rosacea',
    'herpes_zoster',
    'urticaria',
    'normal_or_non_skin'
]

CLASS_TO_IDX = {cls_name: i for i, cls_name in enumerate(CLASSES)}
IDX_TO_CLASS = {i: cls_name for i, cls_name in enumerate(CLASSES)}

CLASS_DISPLAY_NAMES = {
    'acne': 'Acne Vulgaris',
    'eczema': 'Eczema (Atopic / Contact Dermatitis)',
    'psoriasis': 'Psoriasis (Plaque)',
    'tinea_ringworm': 'Tinea / Ringworm (Fungal)',
    'vitiligo': 'Vitiligo (Depigmentation)',
    'impetigo': 'Impetigo (Bacterial Crust)',
    'scabies': 'Scabies (Mite Infestation)',
    'rosacea': 'Rosacea (Facial Erythema)',
    'herpes_zoster': 'Herpes Zoster (Shingles)',
    'urticaria': 'Urticaria (Hives / Wheals)',
    'normal_or_non_skin': 'Normal Skin / Non-Skin Object'
}

def is_skin_image(image: Image.Image, min_skin_ratio: float = 0.20) -> bool:
    """
    Fast HSV/YCbCr color gamut heuristic to verify human skin tone presence.
    Rejects completely irrelevant images (documents, cars, dark noise, text).
    Works across Fitzpatrick skin types I through VI.
    """
    img_rgb = np.array(image.convert('RGB'))
    r, g, b = img_rgb[:, :, 0], img_rgb[:, :, 1], img_rgb[:, :, 2]

    # Standard skin color detection rule in RGB space (Kovacs et al.)
    # R > 95, G > 40, B > 20, max(R,G,B) - min(R,G,B) > 15, |R - G| > 15, R > G, R > B
    skin_mask_1 = (
        (r > 80) & (g > 30) & (b > 15) &
        ((np.maximum(r, np.maximum(g, b)) - np.minimum(r, np.minimum(g, b))) > 12) &
        (r > g) & (r > b)
    )

    # Darker/tanned Fitzpatrick IV-VI skin condition rule
    # High melanin: R > G and G >= B with moderate luminance
    skin_mask_2 = (
        (r > 50) & (g > 30) & (b > 20) &
        (r >= g) & (g >= b) &
        ((r - g) >= 5)
    )

    total_skin_pixels = np.sum(skin_mask_1 | skin_mask_2)
    total_pixels = img_rgb.shape[0] * img_rgb.shape[1]
    skin_ratio = total_skin_pixels / float(total_pixels)
    return skin_ratio >= min_skin_ratio

def get_transforms(is_training: bool = True, image_size: int = 224):
    """
    Clinical image augmentation pipeline.
    Simulates variations in lighting, rotation, and distance common in rural clinic photos.
    """
    if is_training:
        return T.Compose([
            T.Resize((image_size + 32, image_size + 32)),
            T.RandomResizedCrop(image_size, scale=(0.8, 1.0)),
            T.RandomHorizontalFlip(p=0.5),
            T.RandomVerticalFlip(p=0.3),
            T.RandomRotation(degrees=20),
            T.ColorJitter(brightness=0.15, contrast=0.15, saturation=0.1, hue=0.05),
            T.ToTensor(),
            T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])
    else:
        return T.Compose([
            T.Resize((image_size, image_size)),
            T.ToTensor(),
            T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

class SkinDiseaseDataset(Dataset):
    """
    Custom PyTorch Dataset for clinical skin condition photographs.
    """
    def __init__(self, file_paths, labels, transform=None):
        self.file_paths = file_paths
        self.labels = labels
        self.transform = transform

    def __len__(self):
        return len(self.file_paths)

    def __getitem__(self, idx):
        path = self.file_paths[idx]
        label = self.labels[idx]

        try:
            image = Image.open(path).convert('RGB')
        except Exception:
            # Fallback for corrupted images
            image = Image.new('RGB', (224, 224), color=(200, 150, 120))

        if self.transform:
            image = self.transform(image)

        return image, label

def compute_class_weights(labels, num_classes=11):
    """
    Computes inverse-frequency class weights for cross-entropy loss to mitigate class imbalance.
    """
    counts = np.bincount(labels, minlength=num_classes)
    total = len(labels)
    weights = total / (num_classes * np.maximum(counts, 1).astype(float))
    return torch.tensor(weights, dtype=torch.float32)
