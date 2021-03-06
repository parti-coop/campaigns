# encoding: utf-8

class PrivateFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def self.env_storage
    if Rails.env.production?
      :fog
    else
      :file
    end
  end

  storage env_storage

  def initialize(*)
    super

    if Rails.env.production?
      self.fog_credentials = {
        provider:              'AWS',
        aws_access_key_id:     ENV["PRIVATE_S3_ACCESS_KEY"],
        aws_secret_access_key: ENV["PRIVATE_S3_SECRET_KEY"],
        region:                ENV["PRIVATE_S3_REGION"]
      }
      self.fog_directory = ENV["PRIVATE_S3_BUCKET"]
      self.fog_public = false
    end
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  version :xs, if: :image?  do
    process resize_to_fit: [80, nil]
  end

  version :sm, if: :image? do
    process resize_to_fit: [200, nil]
  end

  version :md, if: :image? do
    process resize_to_fit: [400, nil]
  end

  version :lg, if: :image? do
    process resize_to_fit: [700, nil]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token(10)}.#{file.extension}" if original_filename.present?
  end

  before :cache, :save_original_filename
  def save_original_filename(file)
    return if !file.respond_to?(:original_filename) or !model.respond_to?(:original_filename_attribute)
    model[model.original_filename_attribute.to_sym] = file.original_filename
  end

  protected

  def image?(new_file)
    new_file.content_type.start_with? 'image'
  end

  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
end
