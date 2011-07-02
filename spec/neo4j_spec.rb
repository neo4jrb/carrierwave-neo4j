require "spec_helper"

def reset_class(uploader = DefaultUploader)
  class_name = "User"
  Object.send(:remove_const, class_name) rescue nil
  user_class = Object.const_set(class_name, Class.new(Neo4j::Rails::Model))

  user_class.class_eval do
    mount_uploader :image, uploader
  end

  user_class
end

class DefaultUploader < CarrierWave::Uploader::Base; end

describe CarrierWave::Neo4j do
  let(:user_class) { reset_class }
  let(:user) { user_class.new }

  after do
    User.destroy_all
  end

  describe "#image" do
    let(:record) { user_class.new }
    subject { record.image }

    context "when nothing is assigned" do
      it { should be_blank }
    end

    context "when an empty string is assigned" do
      before do
        record.image = ""
        record.save
        record.reload
      end

      it { should be_blank }
    end

    context "when a filename is stored" do
      before do
        record.image = File.open(file_path("tarja.jpg"))
        record.save
        record.reload
      end

      it { should be_an_instance_of DefaultUploader }
      its(:current_path) { should == public_path("uploads/tarja.jpg") }
    end
  end

  describe "#save" do
    context "when remove_image? is true" do
      let(:record) { user_class.new }

      before do
        Neo4j::Transaction.run do
          record.image = File.open(file_path("tarja.jpg"))
          record.save

          record.remove_image = true
          record.save # Getting NotInTransactionException here if not wrapped in a transaction block, maybe Neo4j bug?
          record.reload
        end
      end

      subject { record }

      its(:image) { should be_blank }
    end
  end

  describe "#destroy" do
    let(:record) { user_class.new }

    before do
      record.image = File.open(file_path("tarja.jpg"))
      record.save
    end

    it "also destroys the image" do
      expect { record.destroy }.to change {
        File.exist? public_path("uploads/tarja.jpg")
      }.from(true).to(false)
    end
  end
end
