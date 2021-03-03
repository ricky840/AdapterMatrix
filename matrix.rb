#!/usr/bin/env ruby

require 'firebase'
require 'net/http'
require 'nokogiri'

FIREBASE_DB_BASE_URL = "https://mopub-adcomm-matrix.firebaseio.com"
IOS_MEDIATION = "https://github.com/mopub/mopub-ios-mediation"
AOS_MEDIATION = "https://github.com/mopub/mopub-android-mediation"
CHANGE_LOG_AOS_BASE_URL = "https://github.com/mopub/mopub-android-mediation/blob/master/"
CHANGE_LOG_IOS_BASE_URL = "https://github.com/mopub/mopub-ios-mediation/blob/master/"
CHANGE_LOG_FILE_NAME = "/CHANGELOG.md"

def getChangeLogUrls(available_networks)
  change_log_urls = {}

  available_networks.each do |platform, networks|
    networks.each do |network|
      change_log_url = platform == :ios ? CHANGE_LOG_IOS_BASE_URL + network : CHANGE_LOG_AOS_BASE_URL + network
      change_log_url += CHANGE_LOG_FILE_NAME

      if change_log_urls[platform].nil? 
        change_log_urls[platform] = { network.downcase.to_sym => change_log_url }
      else
        change_log_urls[platform][network.downcase.to_sym] = change_log_url
      end
    end
  end

  return change_log_urls
end

# Takes key and url, returns HTML contents
def getContentFromGitHub(urls)
  content = Hash.new
  begin
    Net::HTTP.start("github.com", 443, :use_ssl => true) do |http|
      urls.each do |key, url|
        uri = URI(url)
        request = Net::HTTP::Get.new uri
        response = http.request request
        content[key] = response.body
      end
    end
  rescue => e
    # Exit script if there is a http error
    puts "Error: #{e.message}"
    exit
  end
  return content
end

def getAvailableNetworks()
	available_networks_ios = []
	available_networks_aos = []

  contents = getContentFromGitHub({:ios => IOS_MEDIATION, :aos => AOS_MEDIATION })

	doc_ios = Nokogiri::HTML(contents[:ios])
	doc_aos = Nokogiri::HTML(contents[:aos])

	doc_ios.css("a[title][href*='/tree/master/']").each do |link|
		if link.content.start_with?(/[A-Z]/)
			available_networks_ios.push(link.content)
		end
	end

	doc_aos.css("a[title][href*='/tree/master/']").each do |link|
		if link.content.start_with?(/[A-Z]/)
      available_networks_aos.push(link.content) unless link.content == "Testing"
		end
	end

	return { :aos => available_networks_aos, :ios => available_networks_ios }
end

def parseList(li) 
  if li.css("ul").length == 0
    return li.content.strip.gsub("\n", " ")
  end

  # If this is nested list, duplicate the list without nested list.
  if li.css("ul").length != 0
    li_duplicated = li.dup
    li_duplicated.css("ul").remove

    # Get the text at the li
    log_messages = [li_duplicated.content.strip.gsub("\n", " ")]

    # Travel through nested list
    nested_log_messages = li.css("ul > li").each_with_object([]) do |li, array|
      array.push(parseList(li))
    end

    return log_messages.push(nested_log_messages)
  end
end

def findCertifiedSDKVersion(change_logs) # array
  sdk_version = "Unknown"
  log_messages = change_logs.flatten
  log_messages.each do |each_msg|
    # See if it includes SDK version after "MoPub". ex) MoPub SDK 5.14.1
    result_after = each_msg.match(/(?:mopub).*[^0-9]([4-7]\.[0-9](?:[0-9])?\.[0-9])[^0-9]?.*/i)

    # See if the message includes SDK version before "MoPub". ex) 5.14.1 MoPub
    result_before = each_msg.match(/.*[^0-9]([4-7]\.[0-9](?:[0-9])?\.[0-9])[^0-9]?.*(?:mopub)/i)

    # If both have the version number, then take the after one. ex) MoPub SDK 5.14.1
    if result_after and result_before
      sdk_version = result_after.captures.first
      break
    elsif result_after and result_before.nil?
      sdk_version = result_after.captures.first
      break
    elsif result_after.nil? and result_before
      sdk_version = result_before.captures.first
      break
    end
  end

  return sdk_version
end

def parseChangeLogHtml(changelog_html)
  doc = Nokogiri::HTML(changelog_html)

  def compareAdapterVerAndFindCertifiedSDKVer(unknown_sdk_adapter_version, change_logs)
    change_logs.each do |each_log|
      if each_log[:certified_sdk_version] != "Unknown"
        adapter_version = createVersionObj(each_log[:version])
        certified_sdk_version = each_log[:certified_sdk_version]
        if unknown_sdk_adapter_version > adapter_version
          return certified_sdk_version
        end
      end
    end
    return "Unknown"
  end

  change_logs = doc.css("article > ul > li").each_with_object([]) do |nodes, array|
    # Adapter Version 
    version = nodes.css("p").first.content.strip

    # Log Messages (each li contents)
    logs = nodes.css("p + ul > li").each_with_object([]) do |li, array|
      array.push(parseList(li))
    end

    # Certified SDK version for this log
    certified_sdk_version = findCertifiedSDKVersion(logs)

    array.push({ :version => version, :logs => logs, :certified_sdk_version => certified_sdk_version })
	end

  # Find certified SDK version for the adapter that has version "Unknown"
  change_logs.each do |each_log|
    if each_log[:certified_sdk_version] == "Unknown"
      unknown_sdk_adapter_version = createVersionObj(each_log[:version])
      each_log[:certified_sdk_version] = compareAdapterVerAndFindCertifiedSDKVer(unknown_sdk_adapter_version, change_logs)
    end
  end
  
  return change_logs
end

def createVersionObj(version_string)
  begin
    return Gem::Version.new(version_string)
  rescue ArgumentError
    return Gem::Version.new("")
  end
end

def findMatchingNetwork(input_network, network_list)
  matched = false

  network_list.each do |network|
    matching_result = network.match(/(#{input_network})/i)
    if matching_result.nil?
      next
    elsif matching_result.captures.first.downcase == "network"
      next
    else
      matched = network
      break
    end
  end

 return matched == false ? false : matched 
end

# Main Starts
firebase = Firebase::Client.new(FIREBASE_DB_BASE_URL)

# Get available networks
puts "Getting available networks"
available_networks = getAvailableNetworks()

# Retreive change log urls
puts "Retreving change log urls"
change_log_urls = getChangeLogUrls(available_networks)

# Structure change log urls
puts "Structuring change log urls"
target_network_urls = change_log_urls.each_with_object({}) do |(platform, network_urls), target_urls|
  network_urls.each do |network, url|
    target_urls[platform] != nil ? target_urls[platform][network] = url : target_urls[platform] = {network => url}
  end
end

# Get change log htmls
puts "Downloading change logs"
changelog_htmls = target_network_urls.each_with_object({}) do |(platform, network_urls), log_htmls|
  log_htmls[platform] = getContentFromGitHub(network_urls)
end

# Parse change log messages
puts "Parsing change logs"
parsed_change_logs = changelog_htmls.each_with_object({}) do |(platform, network_htmls), parsed_logs|
  network_htmls.each do |network, html|
    change_log = parseChangeLogHtml(html)
    parsed_logs[platform] != nil ? parsed_logs[platform][network] = change_log : parsed_logs[platform] = {network => change_log}
  end
end

# Push it to firebase!
puts "Pushing it to firebase"
current_time = Time.now.utc.strftime("%d-%m-%Y_%H-%M-%S")
firebase_result = firebase.set(current_time, parsed_change_logs)
puts firebase_result.code