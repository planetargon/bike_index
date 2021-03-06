require "rails_helper"

RSpec.describe "Users API V2", type: :request do
  include_context :existing_doorkeeper_app
  describe "unauthorized current" do
    it "Sends correct error code when no user present" do
      get "/api/v2/users/current"
      expect(response.response_code).to eq(401)
    end
  end

  describe "authorized current" do
    let!(:token) { create_doorkeeper_token(scopes: scopes) }
    let(:scopes) { "public" }

    context "all scopes" do
      let(:scopes) { all_scopes }
      it "responds with all available attributes with full scoped token" do
        get "/api/v2/users/current", params: { access_token: token.token, format: :json }
        expect(response.response_code).to eq(200)
        result = JSON.parse(response.body)
        expect(result["id"]).to eq(user.id.to_s)
        expect(result["user"].is_a?(Hash)).to be_truthy
        expect(result["bike_ids"].is_a?(Array)).to be_truthy
        expect(result["memberships"].is_a?(Array)).to be_truthy
        expect(result["user"].keys.include?("secondary_emails")).to be_falsey
      end
    end

    it "doesn't include bikes if no bikes scoped" do
      expect(token.scopes.to_s.match("read_bikes").present?).to be_falsey
      get "/api/v2/users/current", params: { access_token: token.token, format: :json }
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result["id"]).to eq(user.id.to_s)
      expect(result["bike_ids"].present?).to be_falsey
    end

    it "doesn't include memberships if no memberships scoped" do
      expect(token.scopes.to_s.match("read_organization_membership").present?).to be_falsey
      get "/api/v2/users/current", params: { access_token: token.token, format: :json }
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result["id"]).to eq(user.id.to_s)
      expect(result["memberships"].present?).to be_falsey
    end

    it "doesn't include memberships if no memberships scoped" do
      get "/api/v2/users/current", params: { access_token: token.token, format: :json }
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result["id"]).to eq(user.id.to_s)
      expect(result["user"].present?).to be_falsey
    end
  end

  describe "current/bikes" do
    before { expect(doorkeeper_app).to be_present }
    it "works if it's authorized" do
      token.update_attribute :scopes, "read_bikes"
      get "/api/v2/users/current/bikes", params: { access_token: token.token, format: :json }
      # get '/api/v2/users/current/bikes', {}, 'Authorization' => "Basic #{Base64.encode64("#{token.token}:X")}"
      result = JSON.parse(response.body)
      expect(result["bikes"].is_a?(Array)).to be_truthy
      expect(response.response_code).to eq(200)
    end
    it "403s if read_bikes_spec isn't in token" do
      get "/api/v2/users/current/bikes", params: { access_token: token.token, format: :json }
      expect(response.response_code).to eq(403)
    end
  end
end
