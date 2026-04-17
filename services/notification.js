const axios = require('axios');

const ONESIGNAL_APP_ID = '761ea292-91d7-4566-8fa5-a7313205f0bf';
const ONESIGNAL_API_KEY = '7gnurhyt4uuyvwtk6j6mm2htj';

async function sendNotificationToPatient(playerId, ticketNumber, patientName, priority) {
  if (!playerId) {
    console.log('Pas de playerId pour ce patient');
    return false;
  }

  const isUrgent = priority === 'urgent';
  const title = isUrgent ? 'URGENT - Votre tour est arrive!' : 'Votre tour est arrive!';
  const message = isUrgent 
    ? 'Ticket ' + ticketNumber + ' - ' + patientName + ', veuillez vous presenter URGENTEMENT au cabinet.'
    : 'Ticket ' + ticketNumber + ' - ' + patientName + ', veuillez vous presenter au cabinet.';

  const messageData = {
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: [playerId],
    headings: { en: title, fr: title },
    contents: { en: message, fr: message },
    data: {
      ticketId: ticketNumber,
      type: "called",
      priority: priority
    }
  };

  try {
    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      messageData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + ONESIGNAL_API_KEY
        }
      }
    );
    console.log('Notification envoyee a ' + patientName + ' (Ticket ' + ticketNumber + ' - ' + priority + ')');
    return true;
  } catch (error) {
    console.error('Erreur envoi notification:', error.response?.data || error.message);
    return false;
  }
}

module.exports = { sendNotificationToPatient };