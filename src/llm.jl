import GoogleGenAI

function get_llm_response(prompt)
    response = GoogleGenAI.generate_content(ENV["GOOGLE_API_KEY"], "gemini-2.0-flash-exp", prompt)
    answer = response.candidates[1][:content][:parts][1].text
    return answer
end
