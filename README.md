
# Kahaani Suno: Story Generator and Audio Narrator

Kahaani Suno is a Flutter-based application that allows users to create stories from simple story ideas and generates an audible narration of the story. This project integrates the **Gemini API** for text generation and the **ElevenLabs API** for converting the generated text into an audio narration.

## Features

- **Story Idea Input**: Users can input a basic story idea, and the app will generate a complete story using the Gemini API.
- **Audio Narration**: The generated story is converted into an audio file using the ElevenLabs API, allowing users to listen to the story.
- **Intuitive UI**: The app is built with Flutter, offering a smooth, interactive, and cross-platform experience.

## Prerequisites

Before running this project, ensure you have:

- Flutter SDK installed. Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install).
- Access to the Gemini API and ElevenLabs API. Obtain API keys from their respective platforms:
  - Get Gemini API from here: [https://gemini-api-docs-link](https://ai.google.dev/) 
  - ElevenLabs API Documentation from here: ([https://elevenlabs-api-docs-link](https://elevenlabs.io/api)) 

## Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/username/myapp.git
   cd kahaani-suno
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app locally**:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=YOUR_GeminiAPI_KEY --dart-define=ELEVEN_LABS_API_KEY=YOUR_ElevenLabsAPI_KEY
   ```
   > Replace `YOUR_GeminiAPI_KEY` and `YOUR_ElevenLabsAPI_KEY` with your actual API keys.

## Usage

- **Enter Story Idea**: Open the app and type a brief description or idea for a story.
- **Generate Story**: Tap the "Generate" button to create a complete story using the Gemini API.
- **Listen to Story**: Tap the "Play" button to hear the story narrated using the ElevenLabs API.

## Technologies Used

- **Flutter**: The UI framework for building cross-platform applications.
- **Gemini API**: For generating the story content based on user input.
- **ElevenLabs API**: For converting the generated text into an audio format.

## Contributing

Contributions are welcome! If you find a bug or have an enhancement request, feel free to submit an issue or pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.


Happy coding!
```
