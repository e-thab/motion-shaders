import cv2
import numpy as np
import math

# assuming both images are the same size
image1 = cv2.imread("sphere1.jpg")
image2 = cv2.imread("sphere2.jpg")


image1 = cv2.blur(image1, (5,5))
image2 = cv2.blur(image2, (5,5))
motionIm = cv2.resize(motionIm, (newW, newH))
grayIm = cv2.cvtColor(image1,cv2.COLOR_BGR2GRAY)
grayIm2 = cv2.cvtColor(image2,cv2.COLOR_BGR2GRAY)
matIx = np.zeros((newH, newW, 1), np.float32)#uint8)
matIxy = np.zeros((newH, newW, 1), np.float32)#uint8)
matIy = np.zeros((newH, newW, 1), np.float32)#uint8)
matIt = np.zeros((newH, newW, 1), np.float32)
matIxIt = np.zeros((newH, newW, 1), np.float32)
matIyIt = np.zeros((newH, newW, 1), np.float32)
uX = np.zeros((newH, newW, 1), np.float32)
uY = np.zeros((newH, newW, 1), np.float32)
u = np.zeros((newH, newW, 3), np.float32)
uMag = np.zeros((newH, newW, 1), np.float32)
color = np.zeros((newH, newW, 1), np.float32)#uint8)
arrowed = np.zeros((newH, newW, 3), np.float32)

        
# Compute gradient images   
# rows
for i in range(1, newH-1):
    # cols
    for j in range(1, newW-1):
        gradImX[i,j,0] = 0.5*(int(grayIm[i-1,j]) + int(grayIm[i+1,j]))
        gradImY[i,j,0] = 0.5*(int(grayIm[i,j-1]) + int(grayIm[i,j+1]))
        matIx[i,j,0] = gradImX[i,j]*gradImX[i,j]
        matIxy[i,j,0] = gradImX[i,j]*gradImY[i,j]
        matIy[i,j,0] = gradImY[i,j]*gradImY[i,j]
        matIt[i,j,0] = float(grayIm2[i,j]) - float(grayIm[i,j])
        matIxIt[i,j,0] = gradImX[i,j]*matIt[i,j,0]
        matIyIt[i,j,0] = gradImY[i,j]*matIt[i,j,0]



##cv2.imshow("matIx", matIx/255.0)
##cv2.imshow("matIy", matIy/255.0)       
##cv2.imshow("It", matIt/255.0)
##cv2.imshow("IxIt", matIxIt/255.0)
##cv2.imshow("IyIt" ,matIyIt/255.0)


# color ranges for visualizing flow angle
th1 = 2*math.pi/3
th2 = 4*math.pi/3
th3 = 2*math.pi
thSize = 2*math.pi/3
# window size
wS = 10
wS1 = wS + 1

maxMag = -1.0
# rows
for i in range(wS, newH-wS):
    # cols
    for j in range(wS, newW-wS):
       # if matIxy[i,j] < 0.1: #G is not invertible/aperture problem
        #    uX[i,j] = 0
        #    uY[i,j] = 0
       # else: 
            winX = sum(sum(matIx[i-wS:i+wS1, j-wS:j+wS1]))
            winY = sum(sum(matIy[i-wS:i+wS1, j-wS:j+wS1])) 
            winXY = sum(sum(matIxy[i-wS:i+wS1, j-wS:j+wS1]))
            winIxT = sum(sum(matIxIt[i-wS:i+wS1, j-wS:j+wS1]))
            winIyT = sum(sum(matIyIt[i-wS:i+wS1, j-wS:j+wS1]))
            det = winX*winY - winXY*winXY #https://en.wikipedia.org/wiki/Determinant
            if det == 0:
                continue
            trace = winX + winY #https://en.wikipedia.org/wiki/Trace_(linear_algebra)
                         
            uX[i,j] = (-winY*winIxT + winXY*winIyT)/det   
            uY[i,j] = (winXY*winIxT - winX*winIyT)/det      
            

            mag = (uX[i,j]*uX[i,j] + uY[i,j]*uY[i,j])**0.5
            maxMag = max(mag, maxMag)
            uX[i,j] = uX[i,j]#*mag
            uY[i,j] = uY[i,j]#*mag
           # if mag < 10:
               # continue
            angle = math.atan2(uY[i,j], uX[i,j]) + math.pi

           
            
            #u[i,j,1] = mag*angle/(2*math.pi)
            uMag[i,j,0] = mag
##            u[i,j,0] = mag*angle/(2*math.pi)
##            blue = 0
##            green = 0
##            red = 0
##            if angle < th1:
##                u[i,j,0] = mag*angle/thSize
####                blue = u[i,j,0]
##            elif angle > th1 and angle < th2:
##                u[i,j,1] = mag*(angle - th1)/thSize
####                green = u[i,j,1]
##            else:
##                u[i,j,2] = mag*(angle - th2)/thSize
####                red = u[i,j,2]

##            if angle < math.pi:
##                u[i,j,0] = mag*angle/math.pi
##            if angle > (0.5*math.pi) and angle <= (1.5*math.pi):
##                u[i,j,1] = mag*(angle - 0.5*math.pi)/math.pi
####                green = u[i,j,1]
##            if angle >= math.pi:
##                u[i,j,2] = mag*(angle - math.pi)/math.pi

            u[i,j,0] = mag*angle/(2*math.pi)
            u[i,j,1] = mag*(2*math.pi - angle)/(2*math.pi)
##                

##            cv2.circle(motionIm, (j,i), 3, (float(blue), float(green), float(red)))
            #endX = int(j + mag*uX[i,j])
            #endY = int(i + mag*uY[i,j])
            #cv2.arrowedLine(motionIm, (j,i), (endX, endY), (blue, green, red), 2)
                              

cv2.imshow("uX", uX)
cv2.imshow("uY", uY)
cv2.imshow("uMag", uMag)
cv2.imshow("u", u)

##cv2.imshow("directions", motionIm*255.0)

cv2.waitKey(0)
cv2.destroyAllWindows()
