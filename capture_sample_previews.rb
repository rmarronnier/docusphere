#!/usr/bin/env ruby

require_relative 'config/environment'
require 'net/http'
require 'uri'
require 'json'
require 'base64'

class QuickLookbookTest
  SELENIUM_URL = "http://selenium:4444"
  BASE_URL = "http://web:3000"
  
  def initialize
    @session_id = nil
  end
  
  def test_previews
    puts "🚀 Testing new Lookbook previews..."
    
    create_session
    
    # Test des nouveaux composants
    test_urls = [
      ["/rails/lookbook/preview/ui/status_badge/all_statuses", "status_badges"],
      ["/rails/lookbook/preview/ui/icon/common_icons", "icons"],
      ["/rails/lookbook/preview/ui/user_avatar/sizes", "avatars"],
      ["/rails/lookbook/preview/forms/field/field_types", "form_fields"],
      ["/rails/lookbook/preview/navigation/breadcrumb/default", "breadcrumb"]
    ]
    
    test_urls.each do |path, name|
      puts "  Testing #{name}..."
      
      # Naviguer vers l'URL
      navigate_to("#{BASE_URL}#{path}")
      sleep 2
      
      # Prendre le screenshot
      screenshot_base64 = take_screenshot
      File.open("tmp/test_#{name}.png", 'wb') do |file|
        file.write(Base64.decode64(screenshot_base64))
      end
      
      puts "  ✅ #{name} captured"
    end
    
  rescue => e
    puts "❌ Error: #{e.message}"
  ensure
    close_session if @session_id
  end
  
  private
  
  def create_session
    uri = URI("#{SELENIUM_URL}/wd/hub/session")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      capabilities: {
        firstMatch: [{}],
        alwaysMatch: {
          browserName: 'chrome',
          'goog:chromeOptions': {
            args: ['--headless', '--no-sandbox', '--disable-dev-shm-usage', '--window-size=1400,1024']
          }
        }
      }
    }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      data = JSON.parse(response.body)
      @session_id = data['value']['sessionId']
      puts "✅ Selenium session created"
    else
      raise "Failed to create session: #{response.code}"
    end
  end
  
  def navigate_to(url)
    uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}/url")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = { url: url }.to_json
    
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end
  
  def take_screenshot
    uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}/screenshot")
    request = Net::HTTP::Get.new(uri)
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      data = JSON.parse(response.body)
      data['value']
    else
      raise "Failed to take screenshot: #{response.code}"
    end
  end
  
  def close_session
    uri = URI("#{SELENIUM_URL}/wd/hub/session/#{@session_id}")
    request = Net::HTTP::Delete.new(uri)
    
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    puts "🔚 Session closed"
  end
end

# Exécuter le test
tester = QuickLookbookTest.new
tester.test_previews