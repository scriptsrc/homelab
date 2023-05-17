from flask import Flask, request
app = Flask(__name__)

from gpt4allj import Model

model = Model('ggml-gpt4all-j.bin')

# Write a flask server to receive post requests and return the generated text
@app.route('/generate', methods=['POST'])
def generate():
    # from IPython import embed; embed()
    return model.generate(request.json['prompt'])

if __name__ == '__main__':
    app.run(debug = True, host='0.0.0.0', port=5000)
