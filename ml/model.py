import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.models as models

class TemperatureScaling(nn.Module):
    """
    Temperature scaling post-processing layer to calibrate model probabilities
    and prevent overconfident predictions on borderline lesions.
    """
    def __init__(self, init_temp=1.2):
        super().__init__()
        self.temperature = nn.Parameter(torch.ones(1) * init_temp)

    def forward(self, logits):
        return logits / self.temperature

class SkinDiseaseMobileNetV3(nn.Module):
    """
    MobileNetV3-Large Transfer Learning model for Skin Disease Classification.
    Optimized for on-device, offline inference on resource-constrained mobile phones.
    """
    def __init__(self, num_classes=11, pretrained=True, dropout=0.3):
        super().__init__()
        # Load pre-trained MobileNetV3-Large
        weights = models.MobileNet_V3_Large_Weights.DEFAULT if pretrained else None
        base_model = models.mobilenet_v3_large(weights=weights)

        # Feature extractor backbone
        self.features = base_model.features
        self.avgpool = base_model.avgpool

        # Inverted residual channels before classifier in MobileNetV3-Large is 960
        in_features = 960

        # Custom lightweight clinical classification head
        self.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.Hardswish(inplace=True),
            nn.Dropout(p=dropout),
            nn.BatchNorm1d(512),
            nn.Linear(512, 128),
            nn.Hardswish(inplace=True),
            nn.Dropout(p=dropout * 0.5),
            nn.Linear(128, num_classes)
        )

        self.temp_scaling = TemperatureScaling()

    def forward(self, x, return_logits=False):
        x = self.features(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        logits = self.classifier(x)

        if return_logits:
            return logits

        calibrated_logits = self.temp_scaling(logits)
        return calibrated_logits

    def freeze_backbone(self):
        """Freezes feature extractor for Stage 1 warm-up."""
        for param in self.features.parameters():
            param.requires_grad = False

    def unfreeze_backbone(self, unfreeze_last_n_blocks=4):
        """
        Selectively unfreezes deeper bottleneck blocks for Stage 2 fine-tuning.
        Keeps low-level primitive filters (edges/textures) frozen.
        """
        total_blocks = len(self.features)
        for i, block in enumerate(self.features):
            if i >= (total_blocks - unfreeze_last_n_blocks):
                for param in block.parameters():
                    param.requires_grad = True
            else:
                for param in block.parameters():
                    param.requires_grad = False

def build_model(num_classes=11, pretrained=True, dropout=0.3):
    return SkinDiseaseMobileNetV3(num_classes=num_classes, pretrained=pretrained, dropout=dropout)
