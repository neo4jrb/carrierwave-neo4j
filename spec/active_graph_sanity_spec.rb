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
    include ActiveGraph::Node
    property :image, type: String
    mount_uploader :image, DefaultUploader
  end
  User
end

describe CarrierWave::ActiveGraph do
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
        # ActiveRecord returns the user hash directly but Neo4j's `.to_json`
        # requires that we select the user hash explicitly
        user_hash = hash["user"]
        expect(user_hash.keys).to include("image")
        expect(user_hash["image"].keys).to include("url")
        expect(user_hash["image"]["url"]).to be_nil
      end

      it "returns valid JSON when to_json is called when image is present" do
        @user.image = File.open(file_path("ong.jpg"))
        @user.save!
        @user.reload
        # again, ActiveRecord does not require the sub-select with `["user"]`
        expect(JSON.parse(@user.to_json)["user"]["image"]).to eq({"url" => "/uploads/ong.jpg"})
      end

      it "does not return anything when a stub image is assigned" do
        # ActiveRecord does permit square bracket assignment to a column
        # Neo4j does not
        @user[:image] = 'ong.jpg'
        @user.save!
        @user.reload
        expect(@user.image).to be_blank
      end
    end

    describe "#image" do
      it "should return blank uploader when nothing has been assigned" do
        expect(@user.image).to be_blank
      end

      it "should return blank uploader when an blank uploader has been assigned" do
        @user[:image] = DefaultUploader.new
        @user.save!
        @user.reload
        other = User.find(@user.id)
        expect(@user.image).to be_blank
        expect(other.image).to be_blank
      end
    end

    describe "#save" do
      it "should do nothing when no file has been assigned" do
        expect(@user.save).to be_truthy
        expect(@user.image).to be_blank
      end

      it "should assign the filename to the database" do
        @user.image = File.open(file_path("ong.jpg"))
        expect(@user.save).to be_truthy
        @user.reload
        # under ActiveRecord these would be equal
        expect(@user[:image]).not_to eq('ong.jpg')
        expect(@user[:image].identifier).to eq('ong.jpg')
        expect(@user.image_identifier).to eq('ong.jpg')
      end

      it "should assign the filename to the database even if uploader was previous nil" do
        expect(@user.save).to be_truthy
        expect(@user.image).to be_blank
        image = File.open(file_path("ong.jpg"))
        expect(@user.update(image: image)).to be_truthy
        @user.reload
        expect(@user[:image]).not_to eq('ong.jpg')
        expect(@user[:image].identifier).to eq('ong.jpg')
        expect(@user.image_identifier).to eq('ong.jpg')
      end

      it "should assign the filename to the database when using #new even if uploader was previous nil" do
        expect(@user.save).to be_truthy
        expect(@user.image).to be_blank
        image = File.open(file_path("ong.jpg"))
        user = User.new(image: image)
        expect(user.save).to be_truthy
        user.reload
        expect(user[:image]).not_to eq('ong.jpg')
        expect(user[:image].identifier).to eq('ong.jpg')
        expect(user.image_identifier).to eq('ong.jpg')
      end

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

      it "does respect `update_column` only after find" do
        @user.image = File.open(file_path("ong.jpg"))
        @user.save!

        # ActiveRecord would respect `update_column`
        User.find(@user.id).update_column(:image, nil)
        expect(@user.reload.image).to be_present
        other = User.find(@user.id)
        expect(other.image).to be_blank
      end
    end

    describe "#destroy" do
    end

    describe "#remote_image_url=" do
      before do
        allow_any_instance_of(CarrierWave::Downloader::Base).to receive(:skip_ssrf_protection?).
          and_return(true)
        stub_request(:get, "www.example.com/test.jpg").to_return(body: File.read(file_path("ong.jpg")))
      end

      it "marks image as changed when setting remote_image_url" do
        expect(@user.image_changed?).to be_falsey
        @user.remote_image_url = 'http://www.example.com/test.jpg'
        expect(@user.image_changed?).to be_truthy
        expect(File.exist?(public_path('uploads/test.jpg'))).to be_falsey
        @user.save!
        @user.reload
        expect(File.exist?(public_path('uploads/test.jpg'))).to be_truthy
        expect(@user.image_changed?).to be_falsey
      end
    end
  end
end
