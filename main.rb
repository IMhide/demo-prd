#
# Requiring Your Gemfile
#

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

#
# Load the .env file
#

Dotenv.load

#
# Requiring monkey patching
#

require './monkey_patches/lanchainrb_monkey_patch'

#
# Require all the module you're creating here
#

loader = Zeitwerk::Loader.new
loader.push_dir('./lib')
loader.setup

#
# Setup Langchain logs
#

Langchain.logger = Logger.new('./logs/lanchainrb.log', **Langchain::LOGGER_OPTIONS)
Langchain.logger.level = Logger::DEBUG

#
# v  Write your main loop downhere v
#

result = Services::MakePrd.call
Services::CreateUserStories.call(prd: result.value!)
