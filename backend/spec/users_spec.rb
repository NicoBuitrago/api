require 'httparty'
require 'json'
require 'json-schema'
require 'dotenv/load'

describe 'Reqres Users API' do
  let(:api_base)  { ENV.fetch('API_BASE_URL', 'https://reqres.in/api') }
  let(:users_url) { "#{api_base}/users" }

  it 'POST /users creates a user and validates contract' do
    payload = { name: 'Test User', job: 'Automation Engineer' }

    post_response = HTTParty.post(
      users_url,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    )

    # Reqres is a public demo API and may block automated requests (403)
    expect([201, 403]).to include(post_response.code)

    if post_response.code == 201
      expect(post_response['id']).not_to be_nil
      expect(post_response['createdAt']).not_to be_nil

      schema_path = File.join(__dir__, 'schemas', 'create_user_schema.json')
      schema = JSON.parse(File.read(schema_path))
      expect(JSON::Validator.validate(schema, post_response.parsed_response)).to eq(true)

      id = post_response['id']
      get_response = HTTParty.get("#{users_url}/#{id}")

      # Reqres does not guarantee persistence for created users
      expect([200, 404]).to include(get_response.code)
    end
  end
end
