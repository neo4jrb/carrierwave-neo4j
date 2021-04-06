require "spec_helper"

def reset_class(uploader = DefaultUploader)
  User.class_eval do
    mount_uploader :image, uploader
  end
  User
end

class User
  include ActiveGraph::Node
  property :image, type: String
end

class DefaultUploader < CarrierWave::Uploader::Base ; end

class PngUploader < CarrierWave::Uploader::Base
  def extension_whitelist
    %w(png)
  end
end

class ProcessingErrorUploader < CarrierWave::Uploader::Base
  process :end_on_an_era

  def end_on_an_era
    raise CarrierWave::ProcessingError, "Bye OngDB"
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
    let(:user) { user_class.new }
    subject { user.image }

    context "when nothing is assigned" do
      it { should be_blank }
    end

    context "when an empty string is assigned" do
      before do
        user.image = ""
        user.save
        user.reload
      end

      it { should be_blank }
    end

    context "when a filename is stored" do
      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save
        user.reload
      end

      it { should be_an_instance_of DefaultUploader }
      its(:current_path) { should == public_path("uploads/ong.jpg") }
    end

    context "when a model is retrieved from the db" do
      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save
        @found = user_class.find(user.uuid)
      end

      subject { @found.image }

      it "has a basic identifier" do
        expect(@found.image_identifier).to eq "ong.jpg"
      end

      it { should be_an_instance_of DefaultUploader }
      its(:url) { should == "/uploads/ong.jpg"}
      its(:current_path) { should == public_path("uploads/ong.jpg") }
    end
  end

  describe "#save" do
    context "when image= is assigned and the user is saved" do
      let(:user) { user_class.new }

      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save
      end

      it "writes the file to disk" do
        expect(File.exist?(public_path('uploads/ong.jpg'))).to be_truthy
      end
    end

    context "when remove_image? is true" do
      let(:user) { user_class.new }

      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save

        user.remove_image = true
        user.save
        user.reload
      end

      subject { user }

      its(:image) { should be_blank }
    end

    context "when validating integrity" do
      subject do
        user = user_class_png.new
        user.image = File.open(file_path("ong.jpg"))
        user
      end

      it { should_not be_valid }
    end

    context "when validating processing" do
      subject do
        user = user_class_error.new
        user.image = File.open(file_path("ong.jpg"))
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

  describe "#update" do
    let(:user) { user_class.new }

    before do
      user.image = File.open(file_path("ong.jpg"))
      user.save
    end

    it "does not flag the uploader for removal" do
      user.image = File.open(file_path("neo4j.png"))
      user.save
      expect(user.remove_image?).to be_falsey
    end

    it "stores the updated file" do
      user.image = File.open(file_path("neo4j.png"))
      user.save
      expect(user.image.current_path).to eq public_path('uploads/neo4j.png')
      expect(user.image.url).to eq '/uploads/neo4j.png'
    end

    it "writes the updated file to disk" do
      user.image = File.open(file_path("neo4j.png"))
      user.save
      expect(File.exist?(public_path('uploads/neo4j.png'))).to be_truthy
    end
  end

  describe "#destroy" do
    let(:user) { user_class.new }

    before do
      user.image = File.open(file_path("ong.jpg"))
      user.save
    end

    it "also destroys the image" do
      file_path = user.image.path
      expect(user.image.current_path).to eq public_path('uploads/ong.jpg')
      expect { user.destroy }.to change {
        File.exist? file_path
      }.from(true).to(false)
    end
  end

  describe "#reload_from_database" do
    context "when used without mutation" do
      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save
        @reloaded = user.reload_from_database
      end

      subject { @reloaded.image }

      it "has an id and image identifier" do
        expect(@reloaded.id).to eq user.id
        expect(@reloaded.image_identifier).to eq "ong.jpg"
      end

      it { should be_an_instance_of DefaultUploader }
      its(:url) { should == "/uploads/ong.jpg"}
      its(:current_path) { should == public_path("uploads/ong.jpg") }
    end
  end

  describe "#reload_from_database!" do
    context "when used with mutation" do
      before do
        user.image = File.open(file_path("ong.jpg"))
        user.save
        user.reload_from_database!
      end

      subject { user.image }

      it "has an image identifier" do
        expect(user.image_identifier).to eq "ong.jpg"
      end

      it { should be_an_instance_of DefaultUploader }
      its(:url) { should == "/uploads/ong.jpg"}
      its(:current_path) { should == public_path("uploads/ong.jpg") }
    end
  end
end
