from fastapi import FastAPI, UploadFile, File
import uvicorn
from io import BytesIO
from PIL import Image
import numpy as np
from keras.layers import TFSMLayer
import os

# TensorFlow warnings कम करने के लिए
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

app = FastAPI()

# ✅ SavedModel path
MODEL_PATH = r"C:\code\potato-project\saved_models\1"

# ✅ Load model
MODEL = TFSMLayer(MODEL_PATH, call_endpoint="serving_default")

# ✅ Class names (training order SAME)
class_names = [
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy"
]

# ✅ Image read function
# ❗ No resize, no /255 (model के अंदर preprocessing है)
def read_file_as_image(data):
    image = Image.open(BytesIO(data)).convert("RGB")
    image = np.array(image, dtype=np.float32)
    return image

# ✅ Test API
@app.get("/ping")
async def ping():
    return {"message": "API is working"}

# ✅ Prediction API
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    image = read_file_as_image(await file.read())
    img_batch = np.expand_dims(image, axis=0)

    # Model prediction
    output = MODEL(img_batch)
    preds = list(output.values())[0].numpy()[0]

    index = int(np.argmax(preds))
    confidence = float(preds[index]) * 100

    # 🔐 Low confidence protection
    if confidence < 65:
        return {
            "disease": "Uncertain",
            "confidence": f"{round(confidence, 2)}%"
        }

    predicted_class = (
        class_names[index]
        .replace("Potato___", "")
        .replace("_", " ")
    )

    return {
        "disease": predicted_class,
        "confidence": f"{round(confidence, 2)}%"
    }

# ✅ Run server
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=7000,
        reload=True
    )
