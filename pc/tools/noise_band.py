#!/usr/bin/env python3
"""Blotch measure of pictures: the standard deviation of the 3 to 40 px band of the luminance over the flat areas.

    python3 pc/tools/noise_band.py A.ppm [B.ppm ...]

The band is the difference of two Gaussian blurs (sigma 1 and 14: structure between about 3 and 40 px); the flat areas are where the
picture's own edges are not (the gradient of a sigma 3 blur is small, the mask grown by 6 px away from every edge), so the number is
the speckle and blotching of the lighting over walls and floors, not the texture's detail. Lower is cleaner. The same measure for
pictures of one view, before and after a lighting change, in the same units (0 to 255 of the encoded luminance)."""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def band_noise(path, low=1.0, high=14.0, edge=6.0):
    image = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64)
    lum = image @ np.array([0.2126, 0.7152, 0.0722])
    band = ndimage.gaussian_filter(lum, low) - ndimage.gaussian_filter(lum, high)
    smooth = ndimage.gaussian_filter(lum, 3.0)
    gx, gy = ndimage.sobel(smooth, axis=1) / 8.0, ndimage.sobel(smooth, axis=0) / 8.0
    steep = np.hypot(gx, gy) > 2.0
    flat = ~ndimage.binary_dilation(steep, iterations=int(edge))
    lit = ndimage.gaussian_filter(lum, high) > 8.0  # not black
    mask = flat & lit
    mask[: int(high * 2)] = False
    mask[-int(high * 2):] = False
    mask[:, : int(high * 2)] = False
    mask[:, -int(high * 2):] = False
    if mask.sum() < 500:
        return float("nan"), 0.0
    return float(band[mask].std()), float(mask.mean())


if __name__ == "__main__":
    for path in sys.argv[1:]:
        std, share = band_noise(path)
        print(f"{path}: band std {std:.3f} over {share:.0%} of the picture")
