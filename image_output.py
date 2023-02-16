import numpy as np
import array
import cv2

# Read output file and convert to image color_img.jpg

origin_image = open("output", "rb")
img = np.zeros([237, 324, 3])

origin_image.read(3)
for r in range(236,-1,-1):
    
    for c in range(324):
        img[r,c] =np.array(array.array('B', origin_image.read(3)))

img = img[...,::-1]

cv2.imwrite('color_img.jpg', img)
