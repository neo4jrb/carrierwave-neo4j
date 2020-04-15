require "spec_helper"

# This spec mirrors the specs found in the CarrierWave::Orm::ActiveRecord spec:
# https://github.com/carrierwaveuploader/carrierwave/blob/master/spec/orm/activerecord_spec.rb
# 
# Use it to sanity-check behaviour since ActiveGraph and ActiveRecord are
# NOT symmetrical.

class DefaultUploader < CarrierWave::Uploader::Base ; end

def reset_class
  Object.send(:remove_const, "User") rescue nil
  Object.const_set("User", Class.new())
  User.class_eval do
    include Neo4j::ActiveNode
    property :image, type: String
    mount_uploader :image, DefaultUploader
  end
  User
end

describe CarrierWave::Neo4j do
  before do
    reset_class
    @user = User.new
  end

  after do
    User.destroy_all
  end

  describe "sanity checks" do

    describe "#mount_uploader" do
      before do
        User.mount_uploader(:image, DefaultUploader)
        @user = User.new
      end

      it "returns valid JSON when to_json is called when image is nil" do
        expect(@user[:image]).to be_blank
        hash = JSON.parse(@user.to_json)
        expect(hash.keys).to include("user")
        user_hash = hash["user"]
        expect(user_hash.keys).to include("image")
        expect(user_hash["image"].keys).to include("url")
        expect(user_hash["image"]["url"]).to be_nil
      end

      it "returns valid JSON when to_json is called when image is present" do
        @user.image = File.open(file_path("ong.jpg"))
        @user.save!
        @user.reload
        expect(JSON.parse(@user.to_json)["user"]["image"]).to eq({"url" => "/uploads/ong.jpg"})
      end

      it "does not return anything when a stub image is assigned" do
        @user[:image] = 'ong.jpg'
        @user.save!
        @user.reload
        expect(@user.image).to be_blank
      end
    end

    describe "#image" do
    end

    describe "#save" do
    end

    describe "#update" do
      it "resets cached value on record reload" do
        @user.image = File.open(file_path("ong.jpg"))
        @user.save!

        expect(@user.reload.image).to be_present

        other = User.find(@user.id)
        other.image = nil
        other.save!

        expect(@user.reload.image).to be_blank
      end

      it "does not respect `update_column`" do
        @user.image = File.open(file_path("ong.jpg"))
        @user.save!

        User.find(@user.id).update_column(:image, nil)

        expect(@user.reload.image).to be_present
        other = User.find(@user.id)
        expect(other.image).to be_present 
      end
    end

    describe "#destroy" do
    end
  end
end
