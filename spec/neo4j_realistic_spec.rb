require "spec_helper"

class RealisticUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end

class Book
  include Neo4j::ActiveNode
  property :cover, type: String
  mount_uploader :cover, RealisticUploader
end

describe CarrierWave::Neo4j do
  after do
    Book.destroy_all
  end

  describe "#uploader" do 
    let(:book) { Book.new }
    subject { book.cover }

    context "when nothing is assigned" do
      it { should be_blank }
    end

    context "when a file is stored to a store_dir" do
      before do
        book.cover = File.open(file_path("ong.jpg"))
        book.save
        book.reload
      end

      it { should be_an_instance_of RealisticUploader }
      its(:current_path) { should == public_path("uploads/book/cover/#{book.id}/ong.jpg") }
    end

    context "when a model is retrieved from the db" do
      before do
        book.cover = File.open(file_path("ong.jpg"))
        book.save
        @found = Book.find(book.id)
      end

      it "has a basic identifier" do
        expect(@found.cover_identifier).to eq "ong.jpg"
      end

      subject { @found.cover }

      it { should be_an_instance_of RealisticUploader }
      its(:url) { should == "/uploads/book/cover/#{book.id}/ong.jpg"}
      its(:current_path) { should == public_path("uploads/book/cover/#{book.id}/ong.jpg") }
    end

    # TODO: look over the AR specs -
    # https://github.com/carrierwaveuploader/carrierwave/blob/master/spec/orm/activerecord_spec.rb
  end

end
