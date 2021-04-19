require "spec_helper"

# RealisticUploader and Book exist to provide a basic test harness with
# standard Ruby code and no metaprogramming of any sort. Because that 
# stuff is really hard to trust, even when you're sure you got it right.

class RealisticUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w(jpg jpeg gif png)
  end
end

class Book
  include ActiveGraph::Node
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

    context "when a db lookup uses `#find`" do
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

    context "when a db look up does not use `#find`" do
      before do
        book.cover = File.open(file_path("ong.jpg"))
        book.save
        @found = Book.find_by_id(book.id)
      end

      it "has a basic identifier" do
        expect(@found.cover_identifier).to eq "ong.jpg"
      end

      subject { @found.cover }

      # There is no way around this. `#url` and `#current_path` depend on the 
      # retrieval of the file from the store but there the only callback 
      # available is `:after_find` which does not fire on `#find_by` queries.
      it { should be_an_instance_of RealisticUploader }
      its(:url) { should be_nil }
      its(:current_path) { should be_nil }

      it "is retrieved with `#reload_from_database!`" do
        @found.reload_from_database!
        expect(@found.cover.url).to eq("/uploads/book/cover/#{@found.id}/ong.jpg")
        expect(@found.cover.current_path).to eq(public_path("uploads/book/cover/#{@found.id}/ong.jpg"))
      end
    end

    context "with CarrierWave::MiniMagick" do
      it "has width and height" do
        book.cover = File.open(file_path("ong.jpg"))
        expect(book.cover.width).to eq 273
        expect(book.cover.height).to eq 273
      end
    end
  end
end
