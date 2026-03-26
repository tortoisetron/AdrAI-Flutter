Route::post('/ask-ai', function (Request $request) {
    $systemPrompt = <<<PROMPT
You are a medical-only AI assistant.

STRICT RULES:
- Answer ONLY medical or healthcare-related questions.
- If the question is not medical, reply:
  "I can only answer medical-related questions."
- Educational information only. No diagnosis.
PROMPT;

    try {
        $client = new \GuzzleHttp\Client([
            'timeout' => 90,
            'http_errors' => false // Prevent Guzzle from throwing exceptions 
        ]);
        
        $response = $client->post('https://telecom-polls-herself-name.trycloudflare.com/api/generate', [
            'json' => [
                'model'  => 'phi3:mini',
                'system' => $systemPrompt,
                'prompt' => $request->prompt,
                'stream' => true,
                'format' => 'json',
                'options' => [
                    'num_predict' => 1500, // Increased to 1500 to prevent truncation on large card sets
                    'temperature' => 0.1, // Lower temperature for slightly faster/more deterministic output
                    'top_p' => 0.9,
                    'top_k' => 40,
                    'repeat_penalty' => 1.1
                ]
            ],
            'stream' => true,
        ]);

        if ($response->getStatusCode() !== 200) {
            return response()->json([
                'error' => 'Upstream AI error',
                'status' => $response->getStatusCode(),
                'details' => $response->getBody()->getContents()
            ], 500);
        }

        return response()->stream(function () use ($response) {
            // Disable any previous buffering
            while (ob_get_level() > 0) {
                ob_end_flush();
            }
            
            $body = $response->getBody();
            while (!$body->eof()) {
                $chunk = $body->read(512); // Slightly smaller read buffer for more granular streaming
                echo $chunk;
                flush();
            }
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no',
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'error' => 'Internal Server Error',
            'message' => $e->getMessage()
        ], 500);
    }
})->withoutMiddleware([\Illuminate\Foundation\Http\Middleware\VerifyCsrfToken::class]); 
