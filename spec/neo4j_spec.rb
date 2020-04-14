require "spec_helper"

def reset_class(uploader = DefaultUploader)
  User.class_eval do
    mount_uploader :image, uploader
  end
  User
end

class User
  include Neo4j::ActiveNode
  property :image, type: String
end

class DefaultUploader < CarrierWave::Uploader::Base; end

class PngUploader < CarrierWave::Uploader::Base
  def extension_whitelist
    %w(png)
  end
end

class ProcessingErrorUploader < CarrierWave::Uploader::Base
  process :end_on_an_era

  def end_on_an_era
    raise CarrierWave::ProcessingError, "Bye Tarja"
  end
end

class DownloadErrorUploader < CarrierWave::Uploader::Base
  def download!(file, headers = {})
    raise CarrierWave::DownloadError
  end
end

describe CarrierWave::Neo4j do
  let(:user_class)          { reset_class }
  let(:user_class_png)      { reset_class(PngUploader) }
  let(:user_class_error)    { reset_class(ProcessingErrorUploader) }
  let(:user_download_error) { reset_class(DownloadErrorUploader) }
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
        record.image = File.open(file_path("tarja.jpg"))
        record.save

        record.remove_image = true
        record.save
        record.reload
      end

      subject { record }

      its(:image) { should be_blank }
    end

    context "when validating integrity" do
      subject do
        user = user_class_png.new
        user.image = File.open(file_path("tarja.jpg"))
        user
      end

      it { should_not be_valid }
    end

    context "when validating processing" do
      subject do
        user = user_class_error.new
        user.image = File.open(file_path("tarja.jpg"))
        user
      end

      it { should_not be_valid }
    end

    context 'when validating download' do
      subject do
        user = user_download_error.new
        user.remote_image_url = 'http://www.example.com/missing.jpg'
        user
      end

      it { should_not be_valid }
    end
  end

  describe "#destroy" do
    let(:record) { user_class.new }

    before do
      record.image = File.open(file_path("tarja.jpg"))
      record.save
    end

    it "also destroys the image" do
      file_path = record.image.path
      expect { record.destroy }.to change {
        File.exist? file_path
      }.from(true).to(false)
    end
  end
end
