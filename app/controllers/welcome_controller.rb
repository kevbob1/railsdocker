class WelcomeController < ApplicationController
    def index
        @hostname = Socket.gethostname
    end
end
